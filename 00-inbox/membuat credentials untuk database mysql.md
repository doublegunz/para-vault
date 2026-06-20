

```
CREATE DATABASE db_learn_laravel_13 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

  

CREATE USER 'learn_laravel_user'@'localhost' IDENTIFIED BY 'password_yang_kuat';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_learn_laravel_13.* TO 'learn_laravel_user'@'localhost';

GRANT CREATE, ALTER, DROP, INDEX ON db_learn_laravel_13.* TO 'learn_laravel_user'@'localhost';

GRANT REFERENCES ON db_learn_laravel_13.* TO 'learn_laravel_user'@'localhost';

FLUSH PRIVILEGES;
```




untuk course ci3

```
CREATE DATABASE db_ci3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'ci3_user'@'localhost' IDENTIFIED BY 'password_yang_kuat';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_ci3.* TO 'ci3_user'@'localhost';

GRANT CREATE, ALTER, DROP, INDEX ON db_ci3.* TO 'ci3_user'@'localhost';

GRANT REFERENCES ON db_ci3.* TO 'ci3_user'@'localhost';

FLUSH PRIVILEGES;
```



untuk course php oop

```
CREATE DATABASE db_php_oop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'oop_user'@'localhost' IDENTIFIED BY 'password_yang_kuat';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_php_oop.* TO 'oop_user'@'localhost';

GRANT CREATE, ALTER, DROP, INDEX ON db_php_oop.* TO 'oop_user'@'localhost';

GRANT REFERENCES ON db_php_oop.* TO 'oop_user'@'localhost';

FLUSH PRIVILEGES;
```