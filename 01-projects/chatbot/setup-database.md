
```
psql -U gungunpriatna -d postgres
```


```
CREATE ROLE mira_app WITH LOGIN;

CREATE DATABASE mira_db
    OWNER mira_app
    ENCODING 'UTF8'
    TEMPLATE template0;
```

```
\password mira_app
```

```
password
```


aktifkan pgvector

```
\c mira_db
```

```

CREATE EXTENSION IF NOT EXISTS vector;
```

```
SELECT extname, extversion
FROM pg_extension
WHERE extname = 'vector';
```


```
psql -h 127.0.0.1 -U mira_app -d mira_db -W
```