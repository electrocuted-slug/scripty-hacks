#!/usr/bin/expect -f
set address [lindex $argv 0];
set prompt "#"
set timeout -1
spawn bluetoothctl
expect "Agent registered\r\n" {
  expect "$prompt" {
    send "default-agent\r"
    expect "Default agent request successful\r\n" {
      expect "$prompt" {
        send "power on\r"
        expect "Changing power on succeeded\r\n" {
          expect "$prompt" {
            send "discoverable on\r"
            expect "Changing discoverable on succeeded\r\n" {
              expect "$prompt" {
                send "pairable on\r"
                expect  "Changing pairable on succeeded\r\n" {
                  expect "$prompt" {
                    send "remove $address\r"
                    expect "$prompt" {
                      send "pair $address\r"
                      expect "$prompt" {
                        send "trust $address\r"
                        expect "$prompt" {
                          send "quit\r"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
