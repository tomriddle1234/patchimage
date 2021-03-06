#!/bin/bash

GAME_TYPE="MKWIIMM"
GAME_NAME="Mario Kart Wiimm"
DOWNLOAD_LINK="http://download.wiimm.de/wiimmfi/mkw-wiimmfi-patcher.7z"

show_notes () {

echo -e \
"************************************************
${GAMENAME}

Custom Mario Kart Wii

Source:			http://wiiki.wii-homebrew.com/Wiimms_Mario_Kart_Fun
Base Image:		Mario Kart Wii (RMC?01)
Supported Versions:	EUR, JAP, USA
************************************************"

}

check_input_image_special () {

	check_input_image_mkwiimm

}

download_wiimm () {

	echo "Choose a Mario Kart Wiimm Distribution

ALL	Build all distributions."
	gawk -F \: 'NR>1 {print $1 "\t" $2}' < script.d/mkwiimm.db
	echo "
type in ALL or an ID"
	read ID

}

wiimmfi () {

	mkdir -p "${HOME}/.patchimage/tools/"
	cd ${HOME}/.patchimage/tools
	rm -rf wiimmfi-patcher/ *.7z*
	wget "${DOWNLOAD_LINK}" &>/dev/null || ( echo "something went wrong downloading ${DOWNLOAD_LINK}" && exit 57 )
	${UNP} mkw-wiimmfi-patcher.7z >/dev/null || ( echo "something went wrong extracting files" && exit 63 )
	mv mkw-wiimmfi-patcher*/ wiimmfi-patcher
	chmod +x wiimmfi-patcher/*.sh
	cd wiimmfi-patcher/

	ln -s "${1}" .
	./create-image.sh >/dev/null || exit 51
	echo "*** 8) storing game in ${PATCHIMAGE_GAME_DIR}/${1##*/}"
	mv ./wiimmfi-images/${1##*/} "${PATCHIMAGE_GAME_DIR}"/

	rm -rf ${HOME}/.patchimage/tools/*

}

build_mkwiimm () {

		DIST=$(gawk -F \: "/^${1}/"'{print $2}' < ${PATCHIMAGE_SCRIPT_DIR}/mkwiimm.db)
		DOWNLOAD=$(gawk -F \: "/^${1}/"'{print $3}' < ${PATCHIMAGE_SCRIPT_DIR}/mkwiimm.db)
		FILENAME=$(gawk -F \: "/^${1}/"'{split($3, a, "/") ; print a[3]}' < ${PATCHIMAGE_SCRIPT_DIR}/mkwiimm.db)

		if [[ ${FILENAME} != mkw* ]]; then
			echo "wrong ID passed from user-input, exiting."
			exit 75
		fi

		rm -rf ${FILENAME/.7z}

		if [[ -f ${PATCHIMAGE_RIIVOLUTION_DIR}/${FILENAME} ]]; then
			echo "*** 5) extracting mkwiimm files"
			${UNP} ${PATCHIMAGE_RIIVOLUTION_DIR}/${FILENAME} >/dev/null || \
				( echo "something went wrong extracting files" && exit 63 )
		elif [[ -f ${PWD}/${FILENAME} ]]; then
			echo "*** 5) extracting mkwiimm files"
			${UNP} ${PWD}/${FILENAME} >/dev/null || \
				( echo "something went wrong extracting files" && exit 63 )
		else
			echo "*** 5) downloading extracting mkwiimm files"
			wget -O ${PATCHIMAGE_RIIVOLUTION_DIR}/${FILENAME} ${DOWNLOAD} >/dev/null || \
				( echo "something went wrong downloading ${DOWNLOAD}" && exit 57 )
			${UNP} ${PATCHIMAGE_RIIVOLUTION_DIR}/${FILENAME} >/dev/null || \
				( echo "something went wrong extracting files" && exit 63 )
		fi

		XD=${PWD}

		cd ${FILENAME/.7z}
		ln -s ${IMAGE} .

		REG=$(gawk '/^RMC/{print $3}' <(wit ll ${IMAGE}))

		case $REG in
			PAL)	REG=P	;;
			NTSC-J)	REG=J	;;
			NTSC-U)	REG=E	;;
		esac
		chmod +x *.sh

		cp -r ${PATCHIMAGE_SCRIPT_DIR}/../override/* ${PWD}/bin/

		if [[ ${MKWIIMM_GAME_LANG} && ${MKWIIMM_MSG_LANG} && ${MKWIIMM_OWN_SAVE} ]]; then
			echo "LANGUAGE=${MKWIIMM_GAME_LANG}
MSGLANG=${MKWIIMM_MSG_LANG}
ISOMODE=wbfs
SPLITISO=
PRIV_SAVEGAME=${MKWIIMM_OWN_SAVE}" > ${PWD}/config.def

			echo "*** 6) creating >${DIST}<, stand by"
			./create-image.sh -a --dest=${PWD}/RMC${REG}${ID}.wbfs >/dev/null || exit 51
		else
			echo "*** 6) creating >${DIST}<"
			./create-image.sh --dest=${PWD}/RMC${REG}${ID}.wbfs || exit 51
		fi

		if [[ ${ID} -lt 23 ]]; then

			echo "*** 7) patching >${DIST}< to use custom server"
			wiimmfi ${PWD}/RMC${REG}${ID}.wbfs || exit 69

			echo "*** 9) cleaning up workdir"
		else
			echo "*** 7) cleaning up workdir"
		fi

		cd ${XD}
		rm -rf ${FILENAME/.7z}

		if [[ ${PATCHIMAGE_COVER_DOWNLOAD} == TRUE ]]; then
			echo -e "*** Z) download_covers\n"
			download_covers RMC${REG}${ID}
		fi

}

patch_wiimm () {

	if [[ ${ID} == ALL ]]; then
		for ID in {06..26}; do
			build_mkwiimm ${ID}
		done
	else

		build_mkwiimm ${ID}

	fi
}
