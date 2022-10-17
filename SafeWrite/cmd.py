from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto.Random import get_random_bytes
from Crypto.Util.Padding import pad, unpad
import base64
from getpass import getpass
from Crypto.Protocol.KDF import PBKDF2


def decrypt(key, salt, content):
  if content.startswith("ciphertext:"):
    ct = content[11:]
    ct = bytes.fromhex(ct)
    salt, IV, ct = ct[0:16], ct[16:32], ct[32:]
    password = getpass().rstrip()
    key = PBKDF2(password, salt, 32, count=10000, hmac_hash_module=SHA256)
    obj = AES.new(key, AES.MODE_CBC, IV)
    try:
      plaintext = unpad(obj.decrypt(ct), 16)
    except Exception as e:
      raise Exception("Wrong password")
    plaintext = plaintext.decode("utf8")
    print(plaintext)
  else:
    if not key or not salt:
      raise Exception("""Key not generated yet. Execute
from JupyterUtils.encryptor import gen_key
key, salt = gen_key()""")
    IV = get_random_bytes(16)
    obj = AES.new(key, AES.MODE_CBC, IV)
    ct = obj.encrypt(pad(bytes(content, encoding="utf8"), 16))
    ct = salt + IV + ct
    ct = ct.hex()
    print("ciphertext:" + ct)
 

if __name__ == "__main__":
  with open("/tmp/ct") as f:
    ct = f.readlines()
  password = getpass()
  pt = decrypt(password, ct)
  if pt is None:
    raise Exception("Fail to decrypt")
  with open("/tmp/pt", "w") as f:
    f.write(pt)
