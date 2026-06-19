#!/usr/bin/python3
#######################################################################################################################
#
# 	Simple digital photo frame photo and video upload app
#
#######################################################################################################################
#
#    Copyright (c) 2026 framp at linux-tips-and-tricks dot de
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

from flask import Flask, request, render_template_string
import os

UPLOAD_DIR = "/photos"

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024 # 50MB

HTML = """
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
body {
    font-family: sans-serif;
    padding: 20px;
    background: #111;
    color: #fff;
    font-size: 18px;
}

h2 {
    font-size: 26px;
}

input, button {
    width: 100%;
    padding: 12px;
    margin: 10px 0;
    font-size: 18px;
}

button {
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 8px;
}

/* Progress bar */
#bar {
    width: 100%;
    background: #333;
    border-radius: 10px;
    overflow: hidden;
    margin-top: 10px;
    display: none;
}

#progress {
    width: 0%;
    height: 20px;
    background: #4CAF50;
}

#dropzone {
    border: 2px dashed #666;
    padding: 25px;
    text-align: center;
    margin: 15px 0;
    border-radius: 10px;
    background: #1a1a1a;
    cursor: pointer;
    transition: 0.2s;
}

#dropzone:hover {
    border-color: #4CAF50;
    background: #222;
}

.dz-title {
    font-size: 20px;
    font-weight: bold;
    margin-bottom: 8px;
}

.dz-sub {
    font-size: 14px;
    color: #aaa;
}

/* Toast */
#toast {
    opacity: 0;
    transition: opacity 0.3s;
    position: fixed;
    bottom: 30px;
    left: 50%;
    transform: translateX(-50%);
    background: #4CAF50;
    color: white;
    padding: 10px 20px;
    border-radius: 8px;
}

#toast.show {
    opacity: 1; 
}
</style>
</head>

<body>

<h2>📸 Foto Upload App</h2>

<div id="bar"><div id="progress"></div></div>

<div id="toast">Upload done ✅</div>

<div id="dropzone">
    <div class="dz-title">📂 Upload fotos and videos</div>
    <div class="dz-sub">Drag & Drop here or click to select</div>
</div>

<input type="file" id="file" multiple accept="image/*,video/*" hidden>

<script>
window.onload = function () {

    const dropzone = document.getElementById("dropzone");
    const fileInput = document.getElementById("file");

    // Klick öffnet File Dialog
    dropzone.addEventListener("click", () => fileInput.click());

    // Drag over
    dropzone.addEventListener("dragover", (e) => {
        e.preventDefault();
        dropzone.style.borderColor = "#4CAF50";
    });

    dropzone.addEventListener("dragleave", () => {
        dropzone.style.borderColor = "#666";
    });

    dropzone.addEventListener("drop", (e) => {
        e.preventDefault();
        fileInput.files = e.dataTransfer.files;
        upload();
    });

    fileInput.addEventListener("change", upload);

    function showToast(text) {
        const t = document.getElementById("toast");
        t.innerText = text;
        t.classList.add("show");

        setTimeout(() => {
            t.classList.remove("show");
        }, 2000);
    }

    function upload() {
        const files = fileInput.files;

        const formData = new FormData();

        for (let f of files) {
            formData.append("file", f);
        }

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "/", true);

        const bar = document.getElementById("bar");
        const progress = document.getElementById("progress");

        bar.style.display = "block";
        progress.style.width = "0%";

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                progress.style.width = (e.loaded / e.total) * 100 + "%";
            }
        };

        xhr.onload = function() {
            progress.style.width = "0%";
            bar.style.display = "none";

            if (xhr.status == 200) {
                showToast("Upload completed ✅");
            } else {
                showToast("Error ❌");
            }
        };

        xhr.onerror = function () {
            bar.style.display = "none";
            showToast("Upload Error ❌");
        };

        xhr.send(formData);
    }
};
</script>

</body>
</html>
"""

@app.route("/", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        files = request.files.getlist("file")
        for file in files:
            if file:
                path = os.path.join(UPLOAD_DIR, file.filename)
                file.save(path)
        return "OK"
    return render_template_string(HTML)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
