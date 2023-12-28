require 'tempfile'
require 'open-uri'
require 'zip'
require 'find'

INPUT_PATH = 'input.csv'
PATTERN_ZIP = '*_bldg_*.gml'
PATTERN_7Z = 'bldg'
N_ATTEMPTS = 10

def apprivoiser(url, fn)
  $stderr.print "apprivoiser #{url}\n"
  dst_path = "#{fn}.tar.gz"
  return if File.exist?(dst_path)
  Dir.mktmpdir {|tmpdir|
    if /zip$/.match(url)
      cmd = <<-EOS
curl -C - -o #{tmpdir}/#{fn}.zip #{url}
      EOS
      cmd = cmd * N_ATTEMPTS
      cmd += <<-EOS
unzip -q -d #{tmpdir}/#{fn} -j #{tmpdir}/#{fn}.zip '#{PATTERN_ZIP}'
      EOS
      print cmd
      system cmd
    elsif /7z$/.match(url)
      cmd = <<-EOS
curl -C - -o #{tmpdir}/#{fn}.7z #{url}
      EOS
      cmd = cmd * N_ATTEMPTS
      cmd += <<-EOS
7z x -o#{tmpdir}/7zx #{tmpdir}/#{fn}.7z -ir!"#{PATTERN_7Z}"
mkdir #{tmpdir}/#{fn}
      EOS
      print cmd
      system cmd
      Find.find("#{tmpdir}/7zx") {|path|
        next unless /#{PATTERN_7Z.gsub('*', '.*')}/.match path
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
#  next unless fn[0..1].to_i == 22 
#  next unless /^22220/.match fn
  apprivoiser(url, fn)
}
