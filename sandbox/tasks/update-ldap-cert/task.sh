#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

echo -n "$PARAM_NAME" > output-folder/$OUTPUT_FILE_NAME
if (grep -q '[^[:space:]]' output-folder/$OUTPUT_FILE_NAME)
then

  echo "Waiting for 30 seconds..."
  sleep 30
  
  [ -f  ~/.ssh/known_hosts ] && ssh-keygen -f ~/.ssh/known_hosts -R ${OPSMAN_HOST}
  if (sshpass -p ${OPSMAN_SSHPASS} ssh -o StrictHostKeyChecking=no -t ubuntu@${OPSMAN_HOST} "echo ${OPSMAN_SSHPASS} | sudo -u tempest-web -S /home/tempest-web/uaa/jdk/bin/keytool -list -alias mykey -keystore /home/tempest-web/uaa/jdk/jre/lib/security/cacerts -storepass changeit")
  then 
    echo Alias mykey already exists.. not replacing the ldap cert..
    exit 0
  else
    echo Alias mykey not found.. proceeding to add the ldap cert..
    sshpass -p ${OPSMAN_SSHPASS} scp -o StrictHostKeyChecking=no output-folder/$OUTPUT_FILE_NAME ubuntu@${OPSMAN_HOST}:/tmp/ldap.crt
    sshpass -p ${OPSMAN_SSHPASS} ssh -o StrictHostKeyChecking=no -t ubuntu@${OPSMAN_HOST} "echo ${OPSMAN_SSHPASS} | sudo -u tempest-web -S cp -p /home/tempest-web/uaa/jdk/jre/lib/security/cacerts /home/tempest-web/uaa/jdk/jre/lib/security/cacerts.orig"
    sshpass -p ${OPSMAN_SSHPASS} ssh -o StrictHostKeyChecking=no -t ubuntu@${OPSMAN_HOST} "echo ${OPSMAN_SSHPASS} | sudo -u tempest-web -S /home/tempest-web/uaa/jdk/bin/keytool -importcert -noprompt -file /tmp/ldap.crt -keystore /home/tempest-web/uaa/jdk/jre/lib/security/cacerts -storepass changeit"
    sshpass -p ${OPSMAN_SSHPASS} ssh -o StrictHostKeyChecking=no -t ubuntu@${OPSMAN_HOST} "echo ${OPSMAN_SSHPASS} |sudo -S service tempest-web restart"
    echo "Waiting for 30 seconds..."
    sleep 30
  fi

else
echo "output-folder/$OUTPUT_FILE_NAME" is empty.. not replacing the ldap cert..
fi
