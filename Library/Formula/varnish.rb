require 'formula'

class Varnish < Formula
  homepage 'http://www.varnish-cache.org/'
  url 'http://repo.varnish-cache.org/source/varnish-3.0.2.tar.gz'
  sha1 '906f1536cb7e728d18d9425677907ae723943df7'

  depends_on 'pkg-config' => :build
  depends_on 'pcre'

  # If stripped, the magic string end pointer isn't found.
  skip_clean :all

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--localstatedir=#{var}"
    system "make install"
    (var+'varnish').mkpath
    
    # Generate the plist file for use with launchd.
    plist_path.write startup_plist
    plist_path.chmod 0644
  end
  
  def caveats
    <<-EOS.undent
    If this is your first install, load the #{plist_path.basename} with:
        sudo ln -nfs #{plist_path} /Library/LaunchDaemons/
        sudo launchctl load -wF /Library/LaunchDaemons/#{plist_path.basename}

    If this is an upgrade and you already have the #{plist_path.basename} loaded:
        sudo launchctl unload -w /Library/LaunchDaemons/#{plist_path.basename}
        sudo ln -nfs #{plist_path} /Library/LaunchDaemons/
        sudo launchctl load -wF /Library/LaunchDaemons/#{plist_path.basename}

    To start the Varnish daemon:
        sudo launchctl start #{plist_name}

    To stop the Varnish daemon:
        sudo launchctl start #{plist_name}

    Keep in mind that the default.vcl needs to contain backends in order to start properly!

    EOS
  end
  
  def startup_plist
    <<-PLIST.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Debug</key>
          <false/>
          <key>GroupName</key>
          <string>wheel</string>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>KeepAlive</key>
          <false/>
          <key>OnDemand</key>
          <false/>
          <key>ProgramArguments</key>
          <array>
            <string>#{HOMEBREW_PREFIX}/sbin/varnishd</string>
            <string>-F</string>
            <string>-a</string>
            <string>:80</string>
            <string>-f</string>
            <string>#{HOMEBREW_PREFIX}/etc/varnish/default.vcl</string>
            <string>-s</string>
            <string>malloc</string>
            <string>-u</string>
            <string>nobody</string>
          </array>
          <key>RunAtLoad</key>
          <false/>
          <key>UserName</key>
          <string>root</string>
        </dict>
      </plist>

    PLIST
  end
end

