# How to Install Redis 8 on Ubuntu 26.04 LTS (Resolute Raccoon)

Most Redis installation guides tell you to add the official APT repository and let `$(lsb_release -cs)` do the work. That works fine on older Ubuntu releases, but when you are running Ubuntu 26.04 LTS (Resolute Raccoon), you might hesitate. Will the Redis APT repository actually recognise the codename `resolute`? Is the package available, or will `apt-get update` throw a `403 Forbidden` error and leave you empty-handed?

The short answer is: it works. Redis officially supports Ubuntu 26.04, and the APT repository at `packages.redis.io` serves packages under the `resolute` codename. By the end of this guide you will have Redis 8.8.0 running as a managed systemd service, verified and ready to use.

## Overview {#overview}

This guide walks through the official APT method, which is the recommended way to install Redis on Ubuntu. You will add the Redis GPG key, register the repository, install the package, and confirm everything is working with a live `PONG` response from `redis-cli`.

### What You'll Build

- Redis 8.8.0 installed from the official `packages.redis.io` APT repository
- Redis running as a `systemd` service that starts automatically on boot
- A verified connection confirmed with `redis-cli ping` and `redis-cli INFO server`

### What You'll Learn

- How to add the official Redis APT repository on Ubuntu 26.04
- How to enable and manage Redis with `systemctl`
- Four different ways to check the Redis version
- When to reach for Redis versus a traditional relational database

### What You'll Need

- Ubuntu 26.04 LTS (Resolute Raccoon)
- A user account with `sudo` access
- Basic familiarity with the terminal

## Step 1: Install Dependencies and Add the GPG Key {#step-1-install-dependencies-and-add-the-gpg-key}

Before registering the Redis repository, you need three tools: `lsb-release` to detect the Ubuntu codename, `curl` to download the GPG key, and `gpg` to import it. Run the following command to make sure all three are present:

```bash
sudo apt-get install lsb-release curl gpg
```

On a fresh Ubuntu 26.04 installation these packages are usually already present, so `apt-get` will confirm they are at their newest versions without downloading anything new.

Next, download the Redis GPG key and convert it into the binary format that APT expects:

```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
```

The `-fsSL` flags tell `curl` to follow redirects silently and fail with an error message if the download does not succeed. The output is piped directly to `gpg --dearmor`, which converts the ASCII-armoured key into a binary `.gpg` file and saves it to `/usr/share/keyrings/`. This location is the modern, recommended place for APT keyring files on Ubuntu.

Finally, set the correct permissions on the keyring file so that APT can read it:

```bash
sudo chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
```

The `644` permission means the file owner (root) can read and write it, while everyone else, including the APT process, can only read it. This is the standard permission for files in `/usr/share/keyrings/`.

## Step 2: Add the Redis APT Repository {#step-2-add-the-redis-apt-repository}

With the GPG key in place, register the Redis APT repository by running:

```bash
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
```

The `$(lsb_release -cs)` part is a command substitution. It runs `lsb_release -cs` inline and inserts the result into the string before it is written to the file. On Ubuntu 26.04, `lsb_release -cs` returns `resolute`, so the final line written to `/etc/apt/sources.list.d/redis.list` will look like this:

```
deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb resolute main
```

The `signed-by` attribute tells APT to verify packages from this repository using exactly the keyring file you registered in Step 1. This prevents APT from accepting packages signed by any other key, which is an important security measure.

## Step 3: Install Redis {#step-3-install-redis}

Now update the package lists to include the new Redis repository, then install Redis:

```bash
sudo apt-get update
sudo apt-get install redis
```

During `apt-get update` you should see APT successfully fetching metadata from `packages.redis.io` for the `resolute` codename. When you run `apt-get install redis`, APT will resolve the `redis` meta-package to two additional packages: `redis-server` (the server binary and configuration) and `redis-tools` (the client utilities including `redis-cli`).

The full output from a successful installation looks like this:

```
Get:1 https://packages.redis.io/deb resolute/main amd64 redis-tools amd64 6:8.8.0-1rl1~resolute1 [541 kB]
Get:2 https://packages.redis.io/deb resolute/main amd64 redis-server amd64 6:8.8.0-1rl1~resolute1 [7,738 kB]
Get:3 https://packages.redis.io/deb resolute/main amd64 redis all 6:8.8.0-1rl1~resolute1 [11.7 kB]
Fetched 8,291 kB in 7s (1,108 kB/s)
Selecting previously unselected package redis-tools.
(Reading database… 272491 files and directories currently installed.)
Preparing to unpack .../redis-tools_6%3a8.8.0-1rl1~resolute1_amd64.deb…
Unpacking redis-tools (6:8.8.0-1rl1~resolute1)…
Selecting previously unselected package redis-server.
Preparing to unpack .../redis-server_6%3a8.8.0-1rl1~resolute1_amd64.deb…
Unpacking redis-server (6:8.8.0-1rl1~resolute1)…
Selecting previously unselected package redis.
Preparing to unpack .../redis_6%3a8.8.0-1rl1~resolute1_all.deb…
Unpacking redis (6:8.8.0-1rl1~resolute1)…
Setting up redis-tools (6:8.8.0-1rl1~resolute1)…
Setting up redis-server (6:8.8.0-1rl1~resolute1)…
Created symlink '/etc/systemd/system/redis.service' → '/usr/lib/systemd/system/redis-server.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/redis-server.service' → '/usr/lib/systemd/system/redis-server.service'.
Setting up redis (6:8.8.0-1rl1~resolute1)…
Processing triggers for man-db (2.13.1-1build1)…
```

Notice the two `Created symlink` lines near the end. The installer automatically registers `redis-server.service` with systemd and adds it to the `multi-user.target.wants` directory. This means Redis is configured to start on boot from the moment the package is installed.

## Step 4: Enable and Start the Service {#step-4-enable-and-start-the-service}

Even though the symlinks were created during installation, it is good practice to explicitly enable and start the service to confirm everything is wired up correctly:

```bash
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

`systemctl enable` ensures the service starts automatically every time the system boots. `systemctl start` brings it up immediately without requiring a reboot. You can confirm the service is active with:

```bash
sudo systemctl status redis-server
```

Look for the line `Active: active (running)` in the output. The `process_supervised: systemd` flag in Redis's own configuration also confirms that Redis is aware it is being managed by systemd, which allows for clean shutdown and restart handling.

## Step 5: Try It Out {#step-5-try-it-out}

With Redis running, open the Redis CLI to send a test command:

```bash
redis-cli
```

Inside the prompt, type `ping`:

```
127.0.0.1:6379> ping
PONG
```

A `PONG` response confirms that the Redis server is listening on the default port `6379` and responding to commands. You can type `exit` to leave the CLI.

### Checking the Redis Version

There are four ways to confirm which version of Redis is installed and running. Each method serves a slightly different purpose.

**Method 1: Check the server binary version**

```bash
redis-server --version
```

```
Redis server v=8.8.0 sha=00000000:1 malloc=jemalloc-5.3.0 bits=64 build=d411285969092c36
```

This checks the version of the installed binary. It is the fastest method and does not require the server to be running.

**Method 2: Check the CLI version**

```bash
redis-cli --version
```

```
redis-cli 8.8.0
```

This checks the version of the client tool. On a single-server setup the CLI and server version will always match, but this is useful when you have a remote server with a different version.

**Method 3: Query the running server directly**

```bash
redis-cli INFO server | grep ^redis_version:
```

```
redis_version:8.8.0
```

This method queries the *live running server* rather than the binary on disk. It is the most accurate way to confirm what version is actually serving requests right now.

**Method 4: Read the full server info from inside the CLI**

```
127.0.0.1:6379> INFO server
# Server
redis_version:8.8.0
redis_git_sha1:00000000
redis_git_dirty:1
redis_build_id:d411285969092c36
redis_mode:standalone
os:Linux 7.0.0-15-generic x86_64
arch_bits:64
monotonic_clock:POSIX clock_gettime
multiplexing_api:epoll
atomicvar_api:c11-builtin
gcc_version:15.2.0
process_id:81510
process_supervised:systemd
run_id:5fc9b6eef79fce2850ce12aed44f60484520b680
tcp_port:6379
server_time_usec:1780146859333187
uptime_in_seconds:326
uptime_in_days:0
hz:10
configured_hz:10
lru_clock:1761963
executable:/usr/bin/redis-server
config_file:/etc/redis/redis.conf
io_threads_active:0
listener0:name=tcp,bind=127.0.0.1,bind=-::1,port=6379
```

The `INFO server` command returns a detailed snapshot of the running server. A few fields worth noting:

- `process_supervised:systemd` confirms Redis is properly integrated with systemd for lifecycle management.
- `listener0:name=tcp,bind=127.0.0.1` confirms Redis is only listening on localhost, which is the safe default for development and production environments where Redis is not meant to be publicly accessible.
- `config_file:/etc/redis/redis.conf` tells you exactly which configuration file is active if you need to make changes later.

## Understanding Redis {#understanding-redis}

Now that Redis is installed and running, it helps to understand what Redis is and when it makes sense to use it.

Redis stands for **Remote Dictionary Server**. It is an open-source, in-memory data store that can function as a database, a cache, and a message broker. Unlike traditional databases such as MySQL or PostgreSQL, Redis stores all of its data in RAM rather than on disk. This is why read and write operations in Redis can complete in under a millisecond, which is orders of magnitude faster than a disk-based database.

Redis was originally created by Salvatore Sanfilippo in 2009 and has since become one of the most widely deployed in-memory data stores in the world. The version you just installed, 8.8.0, brings significant improvements in memory efficiency and supports a broad range of data structures beyond simple key-value pairs.

### Data Structures Redis Supports

Redis is not limited to storing plain strings. It natively understands the following data structures:

- **String**: plain text, numbers, serialised JSON, binary data. Used for counters, tokens, and cached API responses.
- **Hash**: a map of field-value pairs, similar to a PHP associative array. Used to store object representations such as user profiles.
- **List**: an ordered collection of strings. Used for queues, activity feeds, and task lists.
- **Set**: an unordered collection of unique strings. Used for tracking unique visitors, tags, and membership.
- **Sorted Set**: like a Set but with a floating-point score attached to each member. Used for leaderboards and ranked results.
- **Bitmap and HyperLogLog**: compact structures for counting and estimating large sets without storing each individual value.

### When to Use Redis Instead of a Traditional Database

Redis and a relational database are not competitors. They solve different problems and work best when deployed together.

Reach for Redis when:

- **Data is read far more often than it is written.** Caching the result of an expensive database query in Redis means subsequent requests are served from RAM in microseconds rather than waiting for disk I/O.
- **Data has a natural expiry.** Session tokens, OTP codes, rate-limit counters, and temporary flags all benefit from Redis's built-in TTL (time-to-live) feature. The data evicts itself automatically without a cleanup job.
- **You need a fast queue for background jobs.** A Redis-backed queue handles job dispatch and processing with very low overhead.
- **You need real-time features.** Live counters, online presence indicators, pub/sub notifications, and leaderboards are all natural fits for Redis.

Keep your relational database as the primary store when:

- **Data must be permanent and authoritative.** Financial transactions, user accounts, and order records need ACID guarantees and durable storage. Redis's in-memory nature means data can be lost on an unexpected crash unless persistence is explicitly configured.
- **Relationships between entities matter.** Foreign keys, JOIN queries, and referential integrity are the domain of relational databases.
- **You need complex queries.** Aggregations, full-text search with filters, and multi-table reports are better served by SQL.

### The Cache-Aside Pattern

The most common way to combine Redis with a relational database is the **Cache-Aside** pattern. The application checks Redis first. On a cache hit, it returns the data immediately. On a cache miss, it queries the database, stores the result in Redis with a TTL, and then returns the data. The database remains the source of truth at all times, and Redis acts as a fast read layer in front of it.

```
Incoming request
      |
      v
 Check Redis ──── HIT ──── Return cached data
      |
     MISS
      |
      v
  Query MySQL
      |
      v
 Store in Redis (with TTL)
      |
      v
 Return data to client
```

This pattern is what makes Redis so effective as a caching layer. It does not replace your database. It protects it from repeated identical queries.

## Conclusion {#conclusion}

Here are the key takeaways from this guide:

- **Redis APT repository supports Ubuntu 26.04.** The `packages.redis.io` repository serves packages under the `resolute` codename, so the standard APT installation method works without modification.
- **The GPG key step is a security requirement.** Adding the keyring file and referencing it with `signed-by` in the repository entry ensures APT only accepts packages signed by the official Redis team.
- **systemd integration is automatic.** The Redis installer creates the necessary symlinks so the service starts on boot immediately after installation, without any extra configuration.
- **`redis-cli INFO server` is the most informative version check.** Unlike `redis-server --version`, it queries the live running process and reveals configuration details such as bind address and supervision mode.
- **Redis complements, not replaces, relational databases.** Use Redis for caching, sessions, queues, and real-time features. Keep permanent, relational data in MySQL or PostgreSQL.
- **Localhost binding is the safe default.** The `bind=127.0.0.1` setting in the default configuration means Redis is not exposed to the network out of the box, which is the correct posture for both development and production environments.
