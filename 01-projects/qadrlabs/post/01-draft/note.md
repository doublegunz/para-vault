|CVE|What it is|Severity|Affected lines|
|---|---|---|---|
|CVE-2026-111497|Out-of-bounds write in the Brotli decoder; remote code execution, per the project|High|22.x, 24.x, 26.x|
|CVE-2026-106069|TLS hostname-check bypass when a host resolves to an IP address in non-canonical form|High|22.x, 24.x, 26.x|
|CVE-2026-105483|TLS hostname-check bypass when an IP is written in fullwidth digits|High|24.x, 26.x|
|CVE-2026-105482|dns.resolve truncates names that contain a null byte|High|22.x, 24.x, 26.x|
|CVE-2026-105481|Keep-alive socket can process a response written before the request was sent|Medium|22.x, 24.x, 26.x|
|CVE-2026-106072|Certificate validation for non-canonical IPv4 lets DNS names authenticate IP endpoints|Medium|22.x, 24.x, 26.x|
|CVE-2026-106074|randomUUID() and randomInt() caches reused in startup snapshots and single-executable apps|Medium|22.x, 24.x, 26.x|
|CVE-2026-106070|ZipFile returns attacker-controlled bytes after a failed header check|Low|26.x|
|CVE-2026-106071|Permission Model over-grants file access through a wildcard lookup|Low|26.x|
|CVE-2026-106073|Permission Model bypass with fs.realpathSync|Low|22.x, 24.x, 26.x|