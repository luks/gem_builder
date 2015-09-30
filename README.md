# gem_builder

This is my personal script which won't work without ruby installed into /opt/ruby2.1

It is simple tool for packaging ruby gems into debian packages if you don't want to use ruby gems in your projects.

example:

  ./builder.rb rails
  
  Above commad will prepare 33 debian packages at the moment.
  
  then execute dpkg-buildpackage -b on each
  
  TODO automaticaly build prepared packages.
  
  
  


