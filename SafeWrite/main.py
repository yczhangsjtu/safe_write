from tkinter import *
import tkinter.ttk as ttk
from Crypto.Cipher import AES
from hashlib import sha256
import base64

def decrypt(pw, ct):
  if pw == "":
    return None
  if ct == "":
    return ""

  key = sha256(bytes(pw, 'utf-8')).digest()[0:16]
  try:
    ct = base64.b64decode(ct)
  except Exception as e:
    print(e)
    return None

  if len(ct) < 16:
    return None

  nonce, ct = ct[0:16], ct[16:]
  cipher = AES.new(key, AES.MODE_CBC, iv=nonce)
  plaintext = cipher.decrypt(ct)

  if len(plaintext) < 16:
    return None

  for i in range(16):
    if plaintext[i] != 0:
      return None

  return plaintext[16:].decode("utf-8")
 
class Application(Frame):
  def __init__(self, master=None):
    super().__init__(master)
    self.master = master
    self.pack(fill=BOTH, expand=True)

    self.password_bar = Frame(self)
    self.password_label = Label(self.password_bar, text="Password")
    self.password_label.pack(side=LEFT)
    self.password_entry = Entry(self.password_bar, show="*")
    self.password_entry.pack(side=LEFT, expand=True, fill=BOTH)
    self.decrypt_button = Button(self.password_bar, text="Decrypt", command=self.decrypt)
    self.decrypt_button.pack(side=LEFT)

    self.password_bar.pack(side=TOP, fill=X)

    self.texts = Frame(self)
    self.texts.columnconfigure(0, weight=1)
    self.texts.columnconfigure(1, weight=1)
    self.texts.rowconfigure(0, weight=1)
    self.ciphertext = Text(self.texts, borderwidth=1, relief="sunken")
    self.ciphertext.grid(row=0, column=1, sticky=(N,S,E,W))
    self.plaintext = Text(self.texts, borderwidth=1)
    self.plaintext.grid(row=0, column=0, sticky=(N,S,E,W))

    self.texts.pack(side=TOP, fill=BOTH, expand=True)

  def decrypt(self, *args):
    pw = self.password_entry.get()
    ct = self.ciphertext.get("1.0", "end")
    pt = decrypt(pw, ct)
    if pt is None:
      return
    print(pt)
    self.plaintext.delete("1.0", "end")
    self.plaintext.insert("1.0", pt)


root = Tk()
root.minsize(1000, 600)
root.title("Safe Write")
app = Application(master=root)
app.mainloop()
