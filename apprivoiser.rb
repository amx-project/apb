require 'tempfile'
require 'open-uri'
require 'zip'
require 'find'

INPUT_PATH = 'input.csv'
PATTERN = '*_bldg_*_op.gml'

def apprivoiser(url, fn)
  $stderr.print "apprivoiser #{url}\n"
  dst_path = "#{fn}.tar.gz"
  return if File.exist?(dst_path)
  Dir.mktmpdir {|tmpdir|
    if /zip$/.match(url)
      system <<-EOS
curl -o #{tmpdir}/#{fn}.zip #{url}
unzip -q -d #{tmpdir}/#{fn} -j #{tmpdir}/#{fn}.zip '#{PATTERN}'
      EOS
    elsif /7z$/.match(url)
      system <<-EOS
curl -o #{tmpdir}/#{fn}.7z #{url}
7z x -o#{tmpdir}/7zx #{tmpdir}/#{fn}.7z -ir!"#{PATTERN}"
mkdir #{tmpdir}/#{fn}
      EOS
      Find.find("#{tmpdir}/7zx") {|path|
        next unless /#{PATTERN.gsub('*', '.*')}/.match path
        system <<-EOS
mv #{path} #{tmpdir}/#{fn}/#{File.basename(path)}
        EOS
      }
    else
      raise "Could not handle #{url}."
    end
    system <<-EOS
tar czf #{dst_path} -C #{tmpdir} #{fn}
    EOS
    (cid, filename) = `ipfs add #{fn}.tar.gz`.split[1..2]
    $stderr.print <<-EOS
- [#{filename}](https://smb.optgeo.org/ipfs/#{cid}?filename=#{filename})
    EOS
  }
end

File.foreach(INPUT_PATH) {|l|
  url = l.strip
  next if /^#/.match(url)
  fn = url.split('/')[-1].split('_')[0..2].join('_')
#  next unless fn[0..1].to_i > 35
#  next if /^22211/.match fn
  apprivoiser(url, fn)
}
