import win32com.client

def main():
    print("current tool --> lightning file searcher")
    filename = input("Enter a filename: ")

    conn = win32com.client.Dispatch("ADODB.Connection")
    conn.Open("Provider=Search.CollatorDSO;Extended Properties='Application=Windows';")

    query = f"""
    SELECT System.ItemPathDisplay
    FROM SystemIndex
    WHERE System.FileName LIKE '%{filename}%'
    AND System.ItemType != 'System.ItemType:Directory'
    """
    rs = conn.Execute(query)[0]

    found = False

    while not rs.EOF:
        print(rs.Fields.Item("System.ItemPathDisplay").Value)
        found = True
        rs.MoveNext()

    if not found:
        print("No files found.")

if __name__ == "__main__":
    main()
