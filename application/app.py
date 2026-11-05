from flask import Flask, request, render_template_string
import subprocess

app = Flask(__name__)

TEMPLATE = """<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Container Operations Dashboard</title>
<style>
body { font-family: system-ui, sans-serif; max-width: 760px; margin: 2rem auto; padding: 0 1rem; }
h1 { font-size: 1.4rem; }
input[type=text] { width: 60%; padding: .4rem; }
button { padding: .4rem .9rem; }
pre { background: #111; color: #0f0; padding: 1rem; overflow-x: auto; white-space: pre-wrap; }
.note { color: #666; font-size: .85rem; }
</style>
</head>
<body>
<h1>Container Operations Dashboard</h1>
<p class="note">Strumento interno di diagnostica. Verifica la raggiungibilita di un host tramite ping.</p>
<form method="post">
<input type="text" name="target" value="{{ target }}" placeholder="es. 8.8.8.8">
<button type="submit">Esegui ping</button>
</form>
<pre>{{ output }}</pre>
</body>
</html>"""


@app.route("/", methods=["GET", "POST"])
def index():
    output = ""
    target = ""
    if request.method == "POST":
        target = request.form.get("target", "")
        completed = subprocess.run(
            "ping -c 1 " + target,
            shell=True,
            capture_output=True,
            text=True,
            timeout=60,
        )
        output = completed.stdout + completed.stderr
    return render_template_string(TEMPLATE, output=output, target=target)


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
