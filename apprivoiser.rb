require 'tempfile'
require 'open-uri'
require 'zip'

INPUT_PATH = 'input.csv'
CSV_PATH = 'output.csv'
MD_PATH = 'output.md'
KEYWORD = 'bldg'

def apprivoiser(url, fn, csv, md)
  Dir.mktmpdir {|tmpdir|
    system <<-EOS
curl -o #{tmpdir}/#{fn}.zip #{url}
unzip -d #{tmpdir}/#{fn} -j #{tmpdir}/#{fn}.zip '*bldg*'
tar cvzf #{fn}.tar.gz -C #{tmpdir} #{fn}
    EOS
    (cid, filename) = `ipfs add #{fn}.tar.gz`.split[1..2]
    csv.print <<-EOS
#{cid},#{filename}
    EOS
    md.print <<-EOS
- [#{filename}](https://smb.optgeo.org/ipfs/#{cid}?filename=#{filename})
    EOS
  }
end

File.foreach(INPUT_PATH) {|l|
  url = l.strip
  fn = url.split('/')[-1].split('_')[0..2].join('_')
  csv = File.open(CSV_PATH, 'w')
  md = File.open(MD_PATH, 'w')
  apprivoiser(url, fn, csv, md)
  csv.close
  md.close
}

