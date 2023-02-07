#!/bin/bash

printf " __   __   ___  ___  __           ___          __  
/__' |__) |__  |__  |  \     |\/|  |     |  | |__) 
.__/ |    |___ |___ |__/     |  |  |     \__/ |    
                                                   \n\n"


ORANGE='\033[0;33m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m' # No Color

APK_PATH=$1
APP_NAME=`basename "${APK_PATH}" | cut -f 1 -d '.'`
APK_SOURCE_CODE="apps/${APP_NAME}/app/src/main/java"

if [[ $@ == *'dev'* ]]; then
	RULES_PATH="custom-rules/custom_rules_dev.json"
	MODEL_GENERATOR_PATH="custom-model-generator/custom_generator_config_dev.json"
   echo -e "[INFO] ${ORANGE}DEV MODE Enabled${NC}"
else
	RULES_PATH="custom-rules/custom_rules.json;mariana-trench/configuration/rules.json"
   MODEL_GENERATOR_PATH="custom-model-generator/custom_generator_config.json;mariana-trench/configuration/default_generator_config.json"
fi
MODE_SEARCH_PATH="custom-model-generator;mariana-trench/configuration/model-generators"

echo -e "[INFO] RULES_PATH: ${ORANGE}${RULES_PATH}${NC}"
echo -e "[INFO] MODEL_GENERATOR_PATH: ${ORANGE}${MODEL_GENERATOR_PATH}${NC}"
echo -e "[INFO] MODE_SEARCH_PATH: ${ORANGE}${MODE_SEARCH_PATH}${NC}"
echo -e "[INFO] APK_PATH: ${ORANGE}${APK_PATH}${NC}"
echo -e "[INFO] APP_NAME: ${ORANGE}${APP_NAME}${NC}"
echo -e "[INFO] APK_SOURCE_CODE: ${ORANGE}${APK_SOURCE_CODE}${NC}"

if [[ $@ != *'skip'* ]];  then
   if [[ -d apps/ ]]; then
         echo "[VERBOSE] The apps folder is already been created."
   else
      mkdir apps
   fi

   if [[ -d apps/$APP_NAME ]]; then
      echo "[VERBOSE] The apk's directory already exists in the 'apps' folder. Anything inside will be overwritten!"
   else
      echo "[VERBOSE] The apk's directory does not exists and it will be created."
      mkdir apps/$APP_NAME
   fi


   jadx -q -j 10 -d apps/$APP_NAME -e "${APK_PATH}"
   if [ $? -eq 0 ]; then
      echo -e "${LIGHT_GREEN}[JADX]${NC} Completed. Output on \"apps/${APP_NAME}\""
   else
      echo -e "${RED}[JADX]${NC} An issue occurred."
      exit 1
   fi


   find apps/$APP_NAME/app/src/main/java -type f -name '*.java' -exec sh -c 'mv -- "$1" "${1%.java}"' sh {} \;
   if [ $? -eq 0 ]; then
      echo -e "${LIGHT_GREEN}[FIND]${NC} Completed."
   else
      echo -e "${RED}[FIND]${NC} An issue occurred."
      exit 1
   fi


   mkdir apps/$APP_NAME/output
fi

mariana-trench	--system-jar-configuration ~/Library/Android/sdk/platforms/android-30/android.jar \
		--apk-path "${APK_PATH}" \
		--rules-paths "${RULES_PATH}" \
		--model-generator-configuration-paths "${MODEL_GENERATOR_PATH}"  \
		--model-generator-search-paths "${MODE_SEARCH_PATH}" \
		--output-directory apps/$APP_NAME/output \
		--verbosity 2
if [ $? -eq 0 ]; then
   echo -e "${LIGHT_GREEN}[MARIANA-TRENCH]${NC} Completed. Output on \"apps/${APP_NAME}/output\""
else
   echo -e "${RED}[MARIANA-TRENCH]${NC} An issue occurred."
   exit 1
fi

sapp --tool=mariana-trench analyze apps/$APP_NAME/output
if [ $? -eq 0 ]; then
   echo -e "${LIGHT_GREEN}[SAPP]${NC} Analysis completed."
else
   echo -e "${RED}[SAPP]${NC} We got an issue during the analysis."
   exit 1
fi

sapp --database-name=sapp.db --tool mariana-trench server --source-directory=$APK_SOURCE_CODE


