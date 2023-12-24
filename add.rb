CSV_PATH = 'output.csv'
MD_PATH = 'output.md'

csv = File.open(CSV_PATH, 'w')
md = File.open(MD_PATH, 'w')
Dir.glob("*.tar.gz") {|path|
  (cid, filename) = `ipfs add #{path}`.split[1..2]
  csv.print <<-EOS
#{cid},#{filename}
  EOS
  csv.flush
  md.print <<-EOS
- [#{filename}](https://smb.optgeo.org/ipfs/#{cid}?filename=#{filename})
  EOS
  md.flush
  $stderr.print <<-EOS
- [#{filename}](https://smb.optgeo.org/ipfs/#{cid}?filename=#{filename})
  EOS
}
csv.close
md.close