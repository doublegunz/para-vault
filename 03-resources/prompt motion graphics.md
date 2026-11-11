
ref: https://aimarketingit.com/turn-ideas-into-motion-the-gpt-6-astra-motion-graphics-playbook/ 
## Phase 1 Set the brief

## 01 Give the video one job
Before a single frame exists, decide who this is for and the **one thing** they should remember. "Convince founders to try this prototype" is a job. "Make something cool for socials" is not. Everything downstream gets judged against this line.
```
I want to make a short motion graphics video about [TOPIC]. Before we design anything, help me lock the brief.

Ask me up to six questions, one at a time, covering: who the video is for, the single thing they should remember, what they should do next, where it will be watched, what assets I already have, and what would make this fail.

After my answers, write the brief back to me in under 120 words under these headings: Audience, One Message, Desired Action, Viewing Context, Assets On Hand, Failure Risks.

Do not suggest visuals, scenes or music yet. Output only the brief.
```


### 02 Lock the output spec and test the tool chain
Duration, aspect ratio, resolution, audio. Then the question most people skip: can this workspace actually export a video file and generate sound? Astra coordinates the production, but the frames still come from an animation or rendering tool.
```
Here is my brief: [PASTE BRIEF].

Set the technical spec for a first project. Recommend a duration between 20 and 30 seconds, an aspect ratio, a resolution, a frame rate, and whether audio is needed.

Then tell me plainly which parts of this you can produce in this workspace and which need a separate animation or rendering tool. List any capability you do not have access to, including video export and music generation. Do not assume, check and report.

Output a short spec table, then one line describing what I will actually receive at the end. No preamble.
```

## Phase 2 Map the scenes

### 03 Build the 30 second beat sheet
A proven shape for an explainer: hook, premise, transformation, payoff, next action. Put your most compelling image in the first three seconds, because that is the only part most people are guaranteed to watch.
```
Using my brief, write a beat sheet for a 30 second explainer with this structure:

0 to 3 seconds, show the surprising visual or the compelling result.
3 to 9 seconds, establish the problem or premise.
9 to 21 seconds, demonstrate the transformation.
21 to 27 seconds, deliver the payoff.
27 to 30 seconds, give one clear next action.

For each beat give me four things: the time range, the on screen action described as movement over time, the on screen text in eight words or fewer, and the reason that beat exists.

Output as a four column table and nothing else.
```


gun-gun-priatna@qadrlabs:~/learning-lab/video$ codex
Disconnected from this task. Any running work continues.
To reconnect, run:
  codex resume 01a11c24-0ad6-7e91-a9fe-1cca5c37ccc5
Stop the current turn: run codex agents, select this task, and press x.
Token usage so far: total=55,321 input=44,085 (+ 795,136 cached) output=11,236 (reasoning 409)
