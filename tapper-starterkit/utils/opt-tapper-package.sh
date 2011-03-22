
#! /bin/bash

export LANG=C
export PERLBREW_ROOT=/opt/tapper/perl
curl -LO http://xrl.us/perlbrew
chmod +x perlbrew
./perlbrew install
/opt/tapper/perl/bin/perlbrew init
echo "source /opt/tapper/perl/etc/bashrc" >> $HOME/.bashrc
source /opt/tapper/perl/etc/bashrc

perlbrew install perl-5.12.3
perlbrew switch perl-5.12.3

# configure your cpan
cpan Tapper::PRC
cd /
tar -czf /data/tapper/live/repository/packages/tapperutils/opt-tapper64.tar.gz /opt/ # for linux 64bit
tar -czf /data/tapper/live/repository/packages/tapperutils/opt-tapper32.tar.gz /opt/ # for linux 32bit

