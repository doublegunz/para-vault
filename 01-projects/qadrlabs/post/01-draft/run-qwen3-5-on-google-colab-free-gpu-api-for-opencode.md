# Run Qwen3.5 on Google Colab's Free GPU and Use It From opencode on Your Laptop

You want to experiment with open weight models like Qwen3.5 inside an agentic coding tool such as opencode, but your laptop has no dedicated GPU. Running a 9B parameter model on CPU is painfully slow, and renting a cloud GPU just to try things out feels like overkill. Meanwhile, every tutorial assumes you either have an RTX card at home or an API key from a commercial provider.

The good news is that Google Colab gives you a free NVIDIA T4 GPU with 15 GB of VRAM, and that is more than enough to serve Qwen3.5 9B with Ollama. The missing piece is connectivity: Colab runs in Google's cloud, while opencode runs on your laptop. In this tutorial you will bridge that gap with an ngrok tunnel, so your Colab notebook becomes a temporary, OpenAI-compatible LLM server that opencode can talk to like any other provider.

## Overview {#overview}

The setup has three moving parts. First, a Colab notebook runs Ollama on the free T4 GPU and loads Qwen3.5. Second, an ngrok tunnel exposes Ollama's HTTP port to the internet through a public HTTPS URL. Third, opencode on your laptop points to that URL as a custom OpenAI-compatible provider. Once everything is wired up, you can chat with the model and run small coding tasks from your terminal while the actual inference happens on Google's GPU.

### What You'll Build

- A Colab notebook that installs Ollama, serves `qwen3.5:9b` on a T4 GPU, and exposes the API through a public ngrok URL
- An `opencode.json` configuration that registers the Colab endpoint as a custom provider
- A working opencode session on your laptop where code generation is powered by your own free Colab-hosted model

### What You'll Learn

- How to run Ollama as a background server inside a Colab notebook
- How to configure `OLLAMA_HOST`, `OLLAMA_ORIGINS`, and `OLLAMA_CONTEXT_LENGTH` for remote and agentic use
- How to create an ngrok tunnel with pyngrok and store the authtoken safely in Colab Secrets
- How to test an OpenAI-compatible endpoint with curl before connecting any tool to it
- How to register a custom OpenAI-compatible provider in opencode
- Why vLLM is not a good fit for Colab's free T4 tier, and why Ollama is

### What You'll Need

- A Google account with access to Google Colab (the free tier is enough)
- A free ngrok account and its authtoken from the ngrok dashboard
- opencode installed on your laptop (`npm install -g opencode-ai` or the install script from opencode.ai)
- curl and a terminal on your laptop
- Basic familiarity with running notebook cells in Colab

## Step 1: Create a Colab Notebook with a T4 GPU {#step-1-create-a-colab-notebook-with-a-t4-gpu}

Everything on the server side happens inside a single Colab notebook, so the first step is to create one and make sure it actually has a GPU attached. By default, Colab gives you a CPU-only runtime, and Ollama would silently fall back to CPU inference, which is far too slow for interactive use.

Open [colab.research.google.com](https://colab.research.google.com) and create a new notebook. Then go to the menu and select **Runtime > Change runtime type**, choose **T4 GPU** under Hardware accelerator, and click **Save**.

Now verify that the GPU is really there. Run this in the first cell:

```python
!nvidia-smi
```

You should see output similar to this:

```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.54.15              Driver Version: 550.54.15      CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       Off |   00000000:00:04.0 Off |                    0 |
| N/A   38C    P8              9W /   70W |       0MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
```

The important line is `Tesla T4` with `15360MiB` of memory. That 15 GB of VRAM is what allows us to load a quantized 9B model comfortably. If you see an error saying the command is not found, the runtime is still CPU-only; go back to the runtime settings and select the T4 again.

## Step 2: Install and Start Ollama on Colab {#step-2-install-and-start-ollama-on-colab}

Ollama is the inference server we will use. It downloads quantized model weights, manages GPU memory for you, and, most importantly for this tutorial, exposes an OpenAI-compatible API under the `/v1` path. That compatibility is what lets opencode treat our Colab notebook like a regular model provider.

Install Ollama with its official install script in a new cell:

```python
!curl -fsSL https://ollama.com/install.sh | sh
```

The script detects the Linux environment, downloads the Ollama binary, and installs it to `/usr/local/bin`. At the end you will see a line like this, which confirms the GPU was detected:

```
>>> Installing ollama to /usr/local
>>> Downloading Linux amd64 bundle
>>> Creating ollama user...
>>> Adding ollama user to video group...
>>> Adding current user to ollama group...
>>> Ollama install complete.
>>> NVIDIA GPU installed.
```

Ollama normally runs as a systemd service, but Colab notebooks do not have systemd. Instead, we start the server ourselves as a background process using Python's `subprocess` module. Run this in the next cell:

```python
import os
import subprocess

env = os.environ.copy()

# Listen on all interfaces so the ngrok tunnel can reach the server
env["OLLAMA_HOST"] = "0.0.0.0:11434"

# Accept requests from any origin; required when traffic comes through a tunnel
env["OLLAMA_ORIGINS"] = "*"

# Raise the context window; agentic tools send long prompts with tool definitions
env["OLLAMA_CONTEXT_LENGTH"] = "16384"

process = subprocess.Popen(
    ["ollama", "serve"],
    env=env,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
print(f"Ollama server started with PID {process.pid}")
```

Three environment variables do the heavy lifting here. `OLLAMA_HOST=0.0.0.0:11434` makes the server listen on every network interface instead of only `127.0.0.1`, which is necessary because the tunnel process connects to it from outside the loopback interface. `OLLAMA_ORIGINS=*` tells Ollama to accept requests regardless of their origin header; without it, requests arriving through the ngrok domain can be rejected. Finally, `OLLAMA_CONTEXT_LENGTH=16384` raises the default context window, because opencode sends system prompts and tool definitions that easily overflow a small default context, and a truncated context is the number one cause of an agent that seems to forget its instructions mid-task.

Give the server a second to boot, then verify it responds:

```python
!sleep 2 && curl http://127.0.0.1:11434
```

You should see this exact response:

```
Ollama is running
```

That plain text reply is Ollama's health check. If you get `Connection refused` instead, the server did not start; rerun the previous cell and check that the install step completed without errors.

## Step 3: Pull the Qwen3.5 Model {#step-3-pull-the-qwen3-5-model}

With the server running, the next step is to download the model weights. We will use Qwen3.5 9B, the largest model in the Qwen3.5 small series. In its default 4-bit quantization it occupies roughly 6 GB, which fits comfortably in the T4's 15 GB of VRAM while leaving room for the KV cache. It supports reasoning and tool calling, both of which matter for agentic coding.

Pull the model in a new cell:

```python
!ollama pull qwen3.5:9b
```

The download is a few gigabytes, so this takes a couple of minutes on Colab's connection. The output ends like this:

```
pulling manifest
pulling 3f4c9a2b1d8e: 100% ▕██████████████████▏ 6.0 GB
pulling 8ab4c9e21f6a: 100% ▕██████████████████▏  1.5 KB
pulling d18a2f6b3c91: 100% ▕██████████████████▏  494 B
verifying sha256 digest
writing manifest
success
```

If you want faster responses and lighter memory usage at the cost of some quality, `qwen3.5:4b` is a solid alternative; just replace the tag in every command that follows. For a coding agent, though, the 9B model noticeably holds up better on multi-step tasks, so use it if you can.

Now run a quick generation to confirm the model loads onto the GPU:

```python
!ollama run qwen3.5:9b "Reply with exactly one short sentence: which model are you?"
```

After a short load time you get a reply like:

```
I am Qwen3.5, a large language model developed by the Qwen team at Alibaba Cloud.
```

The first request is the slowest because Ollama loads the weights into VRAM at that moment. You can confirm the model is actually on the GPU by checking memory usage:

```python
!nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

```
memory.used [MiB], memory.total [MiB]
7462 MiB, 15360 MiB
```

Roughly 7 GB used means the weights plus the KV cache are resident on the T4, and inference will run at GPU speed.

## Step 4: Expose the API with ngrok {#step-4-expose-the-api-with-ngrok}

At this point Ollama only answers requests inside the Colab virtual machine. Your laptop cannot reach it, because Colab does not give you inbound network access. ngrok solves this by opening an outbound tunnel from the notebook to ngrok's edge servers, which then forward a public HTTPS URL back to port 11434.

You need an authtoken for this. Sign up for a free account at [ngrok.com](https://ngrok.com), then copy the token from **Your Authtoken** in the dashboard. Do not paste the token directly into a notebook cell; Colab has a Secrets feature for exactly this situation. Click the key icon in Colab's left sidebar, add a new secret named `NGROK_AUTHTOKEN`, paste your token as the value, and enable notebook access for it.

Now install pyngrok, the Python wrapper for ngrok:

```python
%pip -q install pyngrok
```

Then open the tunnel:

```python
from google.colab import userdata
from pyngrok import conf, ngrok

# Read the token from Colab Secrets instead of hardcoding it
conf.get_default().auth_token = userdata.get("NGROK_AUTHTOKEN")

# Tunnel to Ollama's port; rewrite the Host header so Ollama accepts the request
tunnel = ngrok.connect(11434, "http", host_header="localhost:11434")
print(f"Public URL: {tunnel.public_url}")
```

Two details in this cell deserve explanation. `userdata.get("NGROK_AUTHTOKEN")` reads the token from Colab Secrets at runtime, so the token never appears in the notebook itself and you can share the notebook without leaking credentials. The `host_header="localhost:11434"` argument tells ngrok to rewrite the `Host` header of every forwarded request; Ollama inspects that header and rejects requests that appear to come from an unexpected host, so without the rewrite you would get 403 responses even though the tunnel itself works.

The output looks like this:

```
Public URL: https://f3a1-34-125-18-92.ngrok-free.app
```

Copy that URL somewhere handy; you will use it in every remaining step. Keep in mind that free ngrok URLs are random and change every time you restart the tunnel, so if you rerun the notebook tomorrow you will get a different address and will need to update your opencode config accordingly.

## Step 5: Test the Endpoint from Your Laptop {#step-5-test-the-endpoint-from-your-laptop}

Before touching opencode, verify the whole chain from your own machine. Testing with curl first is worth the extra minute: if something is broken, you find out here with a clear HTTP error instead of a vague failure inside a coding agent.

Open a terminal on your laptop and list the available models. Replace the URL with your own ngrok URL from Step 4:

```bash
curl https://f3a1-34-125-18-92.ngrok-free.app/v1/models
```

The `/v1/models` path is part of Ollama's OpenAI-compatible API surface. You should get JSON back:

```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen3.5:9b",
      "object": "model",
      "created": 1751414400,
      "owned_by": "library"
    }
  ]
}
```

The `id` field is the exact model name you will reference in opencode. Now send a real chat completion:

```bash
curl https://f3a1-34-125-18-92.ngrok-free.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5:9b",
    "messages": [
      {"role": "user", "content": "Write a one-line Python lambda that squares a number."}
    ]
  }'
```

This request travels from your laptop to ngrok's edge, through the tunnel into the Colab VM, gets processed by Qwen3.5 on the T4, and comes back the same way. The response follows the standard OpenAI schema:

```json
{
  "id": "chatcmpl-482",
  "object": "chat.completion",
  "created": 1751414463,
  "model": "qwen3.5:9b",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "square = lambda x: x ** 2"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 21,
    "completion_tokens": 12,
    "total_tokens": 33
  }
}
```

If both requests succeed, the server side is done. Everything from here on happens on your laptop.

## Step 6: Configure opencode to Use the Colab Endpoint {#step-6-configure-opencode-to-use-the-colab-endpoint}

opencode supports custom providers for any OpenAI-compatible API through its JSON configuration. You describe the provider once, tell it which npm package to use as the client adapter, point the `baseURL` at your endpoint, and list the models it should offer.

Create or open the file `opencode.json` in the root of the project where you want to use the model. You can also place the same block in `~/.config/opencode/opencode.json` to make it available globally, but a per-project config keeps the experiment contained. Add this configuration, replacing the ngrok URL with yours:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "colab-qwen": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Colab Qwen3.5",
      "options": {
        "baseURL": "https://f3a1-34-125-18-92.ngrok-free.app/v1"
      },
      "models": {
        "qwen3.5:9b": {
          "name": "Qwen3.5 9B (Colab T4)",
          "limit": {
            "context": 16384,
            "output": 8192
          }
        }
      }
    }
  }
}
```

Save the file. A few notes on what each part does. The `npm` field selects the client adapter; `@ai-sdk/openai-compatible` is the right choice for any server that implements `/v1/chat/completions`, which Ollama does. The provider key `colab-qwen` is an identifier you choose; it appears in opencode's model list. Under `models`, the key `qwen3.5:9b` must match the model `id` you saw in the `/v1/models` response exactly, because opencode sends it verbatim in the `model` field of every request. The `limit.context` value of 16384 mirrors the `OLLAMA_CONTEXT_LENGTH` we set in Step 2, so opencode knows how much conversation history it can send before it needs to compact. No `apiKey` is set because Ollama does not require one; be aware that this also means anyone who discovers your ngrok URL can use your endpoint, which is acceptable for a short experiment but not something to leave running unattended.

## Step 7: Try It Out {#step-7-try-it-out}

Time to use it. Start opencode inside the project that contains your `opencode.json`:

```bash
opencode
```

Once the TUI opens, switch to your Colab-hosted model with the models command. Type:

```
/models
```

A model picker appears, and you should see your custom provider listed:

```
┌ Select model
│
│  Colab Qwen3.5
│  > Qwen3.5 9B (Colab T4)
│
└ esc to cancel
```

Select **Qwen3.5 9B (Colab T4)** and press Enter. Now give it a small coding task to verify the full round trip:

```
Create a file fizzbuzz.py containing a fizzbuzz function that returns a list
of strings for the numbers 1 through n, plus a __main__ block that prints
the result for n=15.
```

Watch the Colab notebook while this runs; you can add a cell with `!nvidia-smi` and see GPU utilization spike as the model generates. On the opencode side, the agent responds, writes the file, and reports what it did. Verify the result from another terminal:

```bash
python fizzbuzz.py
```

```
['1', '2', 'Fizz', '4', 'Buzz', 'Fizz', '7', '8', 'Fizz', 'Buzz', '11', 'Fizz', '13', '14', 'FizzBuzz']
```

That output confirms the entire chain works: opencode on your laptop drove a model running on a free cloud GPU, through a tunnel, using the same protocol it would use with any commercial provider. Expect responses to be slower than a paid API; a T4 generates roughly 15 to 25 tokens per second with a 9B model, which is fine for exploration but noticeably more relaxed than what you may be used to.

## Why Ollama Instead of vLLM on the Free Tier {#why-ollama-instead-of-vllm}

If you have read about self-hosting LLMs, you may wonder why this tutorial does not use vLLM, the de facto standard for serving open models with an OpenAI-compatible API. The answer comes down to what hardware Colab gives you for free.

The free tier's T4 is an older GPU with CUDA compute capability 7.5. That has two practical consequences. First, the T4 has no native bfloat16 support, and Qwen3.5 ships its weights in BF16; serving it with vLLM on a T4 requires falling back to float16, which works for some models but adds friction and occasional numerical issues. Second, and more decisively, recent vLLM releases have dropped reliable support for compute capability 7.5: version 0.15.x crashes during engine initialization on a T4 because its CUTLASS-based compiler path cannot target sm_75. On top of that, Qwen3.5 support currently requires vLLM nightly builds, which move even further away from legacy GPU support.

Ollama sidesteps all of this. It builds on llama.cpp, which runs quantized GGUF weights on virtually any CUDA GPU, including the T4. You lose some raw throughput compared to vLLM on modern hardware, but for a single user driving a coding agent, that trade is irrelevant; what matters is that it starts reliably on the exact GPU Colab hands you. If you later get access to an A100 or L4 through Colab Pro, revisiting vLLM makes sense, because it serves BF16 weights at full quality and handles concurrent requests far better.

## Limitations of This Setup {#limitations-of-this-setup}

This setup is deliberately a lab experiment, and it is worth being clear-eyed about where it ends. Knowing the limits also tells you exactly what to fix if you outgrow them.

- **Colab sessions are temporary.** The free tier disconnects idle runtimes and enforces daily usage limits. When the runtime dies, your server, model, and tunnel disappear, and you rerun the notebook from the top.
- **The ngrok URL changes every session.** Each restart of the tunnel gives you a new random URL, so you must update `baseURL` in `opencode.json` each time. A free ngrok account allows one static domain, which removes this annoyance if you plan to repeat the experiment often.
- **The endpoint is unauthenticated.** Ollama has no built-in API keys, so anyone with the URL can use your GPU time. The random URL provides weak obscurity, not security. Shut the tunnel down when you are done, or put ngrok's basic auth in front of it.
- **Small models are imperfect agents.** Qwen3.5 9B handles focused, well-scoped coding tasks nicely, but it can occasionally emit a tool call as plain text instead of executing it, and it will not match frontier models on long multi-file refactors. Keep tasks small and specific.

## Conclusion {#conclusion}

You now have a complete, zero-cost pipeline for driving an agentic coding tool with an open model: Qwen3.5 running on a free Colab T4, exposed through a tunnel, consumed by opencode as if it were any commercial API. The same pattern works for any OpenAI-compatible client, so the opencode part is swappable with whatever tool you use next.

- **Ollama turns Colab into an LLM server.** Its OpenAI-compatible `/v1` API and quantized GGUF weights make it the most reliable way to serve models on the free T4 GPU.
- **Environment variables make or break remote access.** `OLLAMA_HOST=0.0.0.0` lets the tunnel reach the server, `OLLAMA_ORIGINS=*` prevents origin rejections, and `OLLAMA_CONTEXT_LENGTH` gives agentic prompts room to breathe.
- **ngrok bridges Colab and your laptop.** A pyngrok tunnel with a `host_header` rewrite exposes port 11434 as a public HTTPS URL, with the authtoken kept safely in Colab Secrets.
- **curl before configuring.** Testing `/v1/models` and `/v1/chat/completions` from your laptop isolates network problems before any tool configuration enters the picture.
- **opencode custom providers are just JSON.** The `@ai-sdk/openai-compatible` adapter plus a `baseURL` and a model map is all it takes to plug any compatible endpoint into your coding agent.
- **Know the free tier's limits.** Rotating URLs, session timeouts, an unauthenticated endpoint, and small-model agent quirks make this a great sandbox and a poor production service.
