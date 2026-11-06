# dvpa-api fixes — before / after

## 1. Insecure deserialisation — flaskblog/blogapi/dashboard.py:248  (B506)
```python
import_post_data = yaml.load(import_data)          # before
import_post_data = yaml.safe_load(import_data)     # after
```
`sed -i 's/yaml\.load(import_data)/yaml.safe_load(import_data)/' flaskblog/blogapi/dashboard.py`

## 2. SQL injection — parameter binding everywhere (B608)
Pattern: placeholders `%s` in the SQL, values as the 2nd argument. Drop the
`f` prefix too — with the f-string still there Bandit keeps flagging the
line even though it's now safe (that's why the course saw "no change" and
concluded FP: the fix WAS real, the heuristic just matches f-strings).

### flaskblog/auth.py:14
```python
cur.execute(f"SELECT * FROM users WHERE email='{username}' AND password='{hashsed_password}'")
cur.execute("SELECT * FROM users WHERE email=%s AND password=%s", [username, hashsed_password])
```
### flaskblog/blogapi/dashboard.py:85
```python
cur.execute(f"SELECT * FROM users WHERE id={request.args.get('uid')}")
cur.execute("SELECT * FROM users WHERE id=%s", [request.args.get('uid')])
```
### flaskblog/blogapi/dashboard.py:100
```python
cur.execute(f"UPDATE `users` SET `email` = '{email}', `full_name` = '{full_name}', `phone_number` = '{phone_number}', `dob` = '{dob}' WHERE `users`.`id` = {request.args.get('uid')}")
cur.execute("UPDATE `users` SET `email` = %s, `full_name` = %s, `phone_number` = %s, `dob` = %s WHERE `users`.`id` = %s",
            [email, full_name, phone_number, dob, request.args.get('uid')])
```
### flaskblog/blogapi/dashboard.py:133  (already safe — just remove the f)
```python
f"INSERT INTO posts (`body`, `slug`, `author`, `title`) VALUES (%s, %s, %s, %s)",
"INSERT INTO posts (`body`, `slug`, `author`, `title`) VALUES (%s, %s, %s, %s)",
```
### flaskblog/blogapi/home.py:26
```python
cur.execute(f"SELECT * FROM posts WHERE slug='{slug}'")
cur.execute("SELECT * FROM posts WHERE slug=%s", [slug])
```
### flaskblog/blogapi/home.py:49  (LIKE: wildcards go in the VALUE, not the SQL)
```python
cur.execute(f"SELECT * FROM posts WHERE title LIKE '%{query}%'")
cur.execute("SELECT * FROM posts WHERE title LIKE %s", ["%" + query + "%"])
```
### flaskblog/blogapi/user.py:74
```python
f"INSERT INTO users (`email`, `full_name`, `password`) VALUES ('{email}', '{full_name}', '{hashed_password}')")
"INSERT INTO users (`email`, `full_name`, `password`) VALUES (%s, %s, %s)", [email, full_name, hashed_password])
```

## 3. Weak hashing — B303/B324 hashlib.md5 (auth.py:13, dashboard.py:67, user.py:71)
Proper fix: a password KDF (bcrypt/argon2/scrypt), e.g.
```python
from werkzeug.security import generate_password_hash, check_password_hash
hashed = generate_password_hash(password)              # store
check_password_hash(row["password"], password)         # verify (fetch by email, compare in Python)
```
This changes the stored hash format → needs a data migration (re-hash on
next login). Talk to the devs; don't "fix" it with sha256 (still fast, unsalted).

## 4. Hardcoded secrets — B105 config.py:4 and :13
```python
SECRET_KEY = os.environ["FLASK_SECRET_KEY"]
password = os.environ.get("ADMIN_PASSWORD")
```
