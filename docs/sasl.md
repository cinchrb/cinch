# @title SASL

# Description

SASL is a modern way of authentication in IRC, solving problems such
as transmitting passwords as plain text (see the DH-BLOWFISH
mechanism) and fully identifying before joining any channels.

Cinch automatically detects which mechanisms are supported by the IRC
network and uses the best available one.

# Mechanisms

Cinch supports all currently used mechanisms.

## DH-BLOWFISH

DH-BLOWFISH is a combination of Diffie-Hellman key exchange and the
Blowfish encryption algorithm. Due to its nature it is more secure
than transmitting the password unencrypted and can be used on
potentially insecure networks.

## PLAIN

The simpler of the two mechanisms simply transmits the username and
password without adding any encryption or hashing. As such it's more
insecure than DH-BLOWFISH and should only be used in combination with
SSL.

# Configuration

In order to use SASL one has to set the username and password options
as follows:

    configure do |c|
      c.sasl.username = "foo"
      c.sasl.password = "bar"
    end
