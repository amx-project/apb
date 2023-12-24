CSV_PATH = "output.csv"

File.foreach(CSV_PATH) {|l|
  (cid, fn) = l.strip.split(',')
  cmd = "ipfs pin add --progress #{cid}"
  system cmd
}

