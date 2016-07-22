#!/bin/bash

if [[ "$STANDBY" -ge 1 ]]; then
  su - gpadmin -c 'echo -e "GPDB\nn\nGPDB\n\n\nn\nn\nn\ny\nsmdw\n" | gpcmdr --setup' || [[ $? == 255 ]]
else
  su - gpadmin -c 'echo -e "GPDB\nn\nGPDB\n\n\nn\nn\nn\nn\n" | gpcmdr --setup' || [[ $? == 255 ]]
fi

su - gpadmin -c 'gpcmdr --start'
