from flask import Flask, request, jsonify
from flask_cors import CORS
import hashlib, time, json

app = Flask(__name__)
CORS(app)

# -------- Authorized Nodes --------
AUTHORIZED_NODES = ["AIIMS", "IITB", "IITD", "IITK", "IITM", "IITKGP", "IITR", "IITG", "IITBH", "IISc", "IISER", "NITK", "NITR", "NITW", "NITD", "NITJ", "NITC", "NITP", "NITM", "NITG", "BITS", "IIIT-H", "IIIT-B", "IIIT-D", "IIIT-NR", "ISI", "TIFR", "JNU", "DU", "AMU", "BHU", "PU", "AU", "CU", "MU", "GU", "RU", "SU", "TU", "VIT", "SRM", "MIT", "SNU", "Ashoka", "OPJGU", "JGU", "IGNOU", "IIM-A", "IIM-B", "IIM-C", "IIM-L"]

# -------- User Store --------
# Students: { student_id: { "password": hashed, "university": "IITB" } }
# Admins:   { node_name:   { "password": hashed, "role": "admin" } }
STUDENTS = {}
ADMINS = {
    # Default admin accounts — one per node (password = node name lowercase)
    node: {"password": hashlib.sha256(node.lower().encode()).hexdigest(), "role": "admin"}
    for node in AUTHORIZED_NODES
}

def hash_password(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()

# -------- Helper: Hashing --------
def hash_block(block):
    block_str = json.dumps(block, sort_keys=True).encode()
    return hashlib.sha256(block_str).hexdigest()

# -------- Blockchain --------
class Blockchain:
    def __init__(self):
        self.chain = []
        self.add_genesis()

    def add_genesis(self):
        genesis = {
            "index": 0,
            "timestamp": time.time(),
            "student_id": "NA",
            "course": "NA",
            "credits": 0,
            "prev_hash": "0",
            "creator": "system"
        }
        genesis["hash"] = hash_block(genesis)
        self.chain.append(genesis)

    def add_block(self, student_id, course, credits, creator):
        if creator not in AUTHORIZED_NODES:
            return None, f"❌ Block rejected: {creator} not authorized!"

        block = {
            "index": len(self.chain),
            "timestamp": time.time(),
            "student_id": student_id,
            "course": course,
            "credits": credits,
            "prev_hash": self.chain[-1]["hash"],
            "creator": creator
        }
        block["hash"] = hash_block(block)
        self.chain.append(block)
        return block, f"✅ Block {block['index']} added for Student {student_id} by {creator}."

    def get_student_records(self, student_id):
        return [block for block in self.chain if block["student_id"] == student_id]

    def get_node_records(self, node):
        return [block for block in self.chain if block.get("creator") == node]

    def get_block_by_index(self, index):
        try:
            index = int(index)
            if 0 <= index < len(self.chain):
                return self.chain[index]
        except:
            pass
        return None

bc = Blockchain()

# ======================================================================
# AUTH ROUTES
# ======================================================================

@app.route("/login", methods=["POST"])
def login():
    data = request.json
    role = data.get("role")          # "student" or "admin"
    username = data.get("username")  # student_id OR node name
    password = data.get("password")

    if not role or not username or not password:
        return jsonify({"success": False, "message": "Missing fields."}), 400

    hashed = hash_password(password)

    if role == "student":
        user = STUDENTS.get(username)
        if not user:
            return jsonify({"success": False, "message": "❌ Student ID not found."}), 401
        if user["password"] != hashed:
            return jsonify({"success": False, "message": "❌ Incorrect password."}), 401
        return jsonify({
            "success": True,
            "role": "student",
            "student_id": username,
            "university": user.get("university", "")
        })

    elif role == "admin":
        user = ADMINS.get(username)
        if not user:
            return jsonify({"success": False, "message": "❌ Admin node not found."}), 401
        if user["password"] != hashed:
            return jsonify({"success": False, "message": "❌ Incorrect password."}), 401
        return jsonify({
            "success": True,
            "role": "admin",
            "node": username
        })

    return jsonify({"success": False, "message": "❌ Invalid role."}), 400


@app.route("/register/student", methods=["POST"])
def register_student():
    """Register a new student. Can be called by admin or directly."""
    data = request.json
    student_id = data.get("student_id")
    password = data.get("password")
    university = data.get("university")

    if not student_id or not password or not university:
        return jsonify({"success": False, "message": "Missing fields."}), 400

    if university not in AUTHORIZED_NODES:
        return jsonify({"success": False, "message": f"❌ University {university} not authorized."}), 400

    if student_id in STUDENTS:
        return jsonify({"success": False, "message": f"ℹ️ Student {student_id} already exists."}), 200

    STUDENTS[student_id] = {
        "password": hash_password(password),
        "university": university
    }
    return jsonify({"success": True, "message": f"✅ Student {student_id} registered under {university}."})


@app.route("/students", methods=["GET"])
def list_students():
    """List all registered student IDs (no passwords)."""
    return jsonify([
        {"student_id": sid, "university": info["university"]}
        for sid, info in STUDENTS.items()
    ])


# ======================================================================
# BLOCKCHAIN ROUTES (unchanged from original)
# ======================================================================

@app.route("/")
def home():
    return jsonify({"message": "Blockchain API is running", "status": "active"})

@app.route("/add_block", methods=["POST"])
def add_block():
    data = request.json
    block, msg = bc.add_block(
        data.get("student_id"),
        data.get("course"),
        data.get("credits"),
        data.get("creator")
    )
    return jsonify({"message": msg, "block": block})

@app.route("/chain", methods=["GET"])
def get_chain():
    return jsonify(bc.chain)

@app.route("/chain_length", methods=["GET"])
def get_chain_length():
    return jsonify({"length": len(bc.chain)})

@app.route("/block/<int:index>", methods=["GET"])
def get_block(index):
    block = bc.get_block_by_index(index)
    if block:
        return jsonify(block)
    return jsonify({"error": "Block not found"}), 404

@app.route("/add_node", methods=["POST"])
def add_node():
    data = request.json
    node = data.get("node")
    if node not in AUTHORIZED_NODES:
        AUTHORIZED_NODES.append(node)
        # Auto-create admin account for new node
        ADMINS[node] = {
            "password": hash_password(node.lower()),
            "role": "admin"
        }
        return jsonify({"message": f"✅ Node {node} added.", "nodes": AUTHORIZED_NODES})
    return jsonify({"message": f"ℹ️ Node {node} already exists.", "nodes": AUTHORIZED_NODES})

@app.route("/nodes", methods=["GET"])
def get_nodes():
    return jsonify(AUTHORIZED_NODES)

@app.route("/search/<student_id>", methods=["GET"])
def search_student(student_id):
    records = bc.get_student_records(student_id)
    return jsonify(records if records else {"message": "No records found"})

@app.route("/latest_block", methods=["GET"])
def get_latest_block():
    if bc.chain:
        return jsonify(bc.chain[-1])
    return jsonify({"error": "No blocks in chain"}), 404

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
