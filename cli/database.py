import sqlite3
from typing import List
import datetime
from model import Todo

conn = sqlite3.connect('medicare.db')
c = conn.cursor()
