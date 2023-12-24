require 'tempfile'
require 'open-uri'
require 'zip'
require 'find'

INPUT_PATH = 'input.csv'
CSV_PATH = 'output.csv'
MD_PATH = 'output.md'
PATTERN = '*_bldg_*_op.gml'

def apprivoiser(url, fn, csv, md)
  $stderr.print "apprivoiser #{url}\n"
  Dir.mktmpdir {|tmpdir|
    if /zip$/.match(url)
      system <<-EOS
curl -o #{tmpdir}/#{fn}.zip #{url}
unzip -d #{tmpdir}/#{fn} -j #{tmpdir}/#{fn}.zip '#{PATTERN}'
      EOS
    elsif /7z$/.match(url)
      p url
      p fn
      system <<-EOS
curl -o #{tmpdir}/#{fn}.7z #{url}
7z x -o#{tmpdir}/7zx #{tmpdir}/#{fn}.7z
mkdir #{tmpdir}/#{fn}
      EOS
      Find.find("#{tmpdir}/7zx") {|path|
        next unless /#{PATTERN}.gsub('*', '.*')/.match path
        system <<-EOS
mv #{path} #{tmpdir}/#{fn}/#{File.basename(path)}
        EOS
      }
    else
      raise "Could not handle #{url}."
    end
    system <<-EOS
tar cvzf #{fn}.tar.gz -C #{tmpdir} #{fn}
    EOS
    (cid, filename) = `ipfs add #{fn}.tar.gz`.split[1..2]
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
end

File.foreach(INPUT_PATH) {|l|
  url = l.strip
  next if /^#/.match(url)
  fn = url.split('/')[-1].split('_')[0..2].join('_')
  csv = File.open(CSV_PATH, 'w')
  md = File.open(MD_PATH, 'w')
  apprivoiser(url, fn, csv, md)
  csv.close
  md.close
}

