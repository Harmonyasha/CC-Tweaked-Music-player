from flask import Flask, jsonify, request, render_template,send_file
import ngrok_library
app = Flask(__name__,static_url_path='')
currentmsg = ""

@app.route("/audio/<name>",methods=["post"])
def audio(name):
  return send_file(name, as_attachment=True)
  #return jsonify(lines)
  

if __name__ == "__main__":
  app.run(port = 5237)

    
