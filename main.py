from flask import Flask, jsonify, request, render_template,send_file
app = Flask(__name__,static_url_path='')

@app.route("/audio/<name>",methods=["post"])
def audio(name):
  return send_file(name, as_attachment=True)
  

if __name__ == "__main__":
  app.run(port = 5237)

    
