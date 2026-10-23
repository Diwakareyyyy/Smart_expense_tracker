from database.connection import engine

try:
    connection = engine.connect()
    print("Connected Successfully")
    connection.close()
except Exception as e:
    print(e)