#!/usr/bin/bash
# shellcheck disable=SC2034

# Copyright (c) 2021-2022 @grm34 Neternels Team
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# lib/main.sh
# ===========
MSG_ERR_LINUX="vous devez exécuter ce script sous Linux"
MSG_ERR_PWD="exécutez ce script depuis le dossier ZenMaxBuilder"
MSG_ERR_KDIR="dossier du noyau invalide (voir config.sh)"
MSG_ERR_EOPT="vous devez spécifier une option (voir --help)"
MSG_ERR_MARG="argument manquant pour"
MSG_ERR_IOPT="option invalide"
MSG_ERR_KBOARD="interruption clavier"
MSG_NOTE_START="Compilation d'un nouveau Noyau Android"
MSG_NOTE_LINUXVER="Make kernelversion (version du noyau)"
MSG_NOTE_CANCEL="Compilation annulée"
MSG_NOTE_SUCCES="Compilation réussie après"
MSG_NOTE_ZIPPED="Zip réussi, regardez dans le dossier builds"

# lib/manager.sh
# ==============
MSG_HELP_H="voir ce message et quitter"
MSG_HELP_S="lancer la compilation d'un noyau"
MSG_HELP_U="mise à jour du script et toolchains"
MSG_HELP_L="voir la liste de vos noyaux (out)"
MSG_HELP_T="voir le dernier tag Linux (version)"
MSG_HELP_M="envoyer un message sur Telegram"
MSG_HELP_F="envoyer un fichier sur Telegram"
MSG_HELP_Z="créer un zip flashable du noyau"
MSG_HELP_INFO="Plus d'informations sur"
MSG_ERR_CONFIRM="entrez yes ou no"
MSG_ERROR="Erreur"
MSG_ERR_LINE="Ligne"
MSG_ERR_FROM="Depuis"
MSG_EXIT="Sortie de ZenMaxBuilder"
MSG_NOTE_CLEAN_AK3="Nettoyage du dépôt AnyKernel"
MSG_NOTE_LISTKERNEL="Liste des Noyaux Android"
MSG_ERR_LISTKERNEL="aucun noyau trouvé dans le dossier out"
MSG_NOTE_LTAG="Détection de Linux Stable (patientez)"
MSG_SUCCESS_LTAG="Dernier tag Linux Stable"
MSG_ERR_LTAG="tag Linux Stable invalide"

# lib/flasher.sh
# ==============
MSG_NOTE_ZIP="Création du zip"
MSG_ERR_DIR="dossier non trouvé"
MSG_NOTE_SIGN="Signature du fichier Zip avec AOSP keys"
MSG_ERR_IMG="image du noyau invalide"

# lib/maker.sh
# ============
MSG_NOTE_MAKE_CLEAN="Make clean (nettoyage du noyau)"
MSG_NOTE_MRPROPER="Make mrproper (purge du noyau)"
MSG_NOTE_DEFCONFIG="Make config (lancement de la configuration)"
MSG_NOTE_MENUCONFIG="Make menuconfig (mode édition du noyau)"
MSG_NOTE_SAVE="Sauvegarde de la configuration"
MSG_NOTE_MAKE="Nouvelle compilation de"

# lib/requirements.sh
# ===================
MSG_ERR_OS="OS non trouvé, des dépendances peuvent être requises"

# lib/telegram.sh
# ===============
MSG_NOTE_SEND="Envoi du message sur Telegram"
MSG_ERR_API="vous devez d'abord configurer Telegram API"
MSG_NOTE_UPLOAD="Envoi sur Telegram"
MSG_ERR_FILE="fichier non trouvé"
MSG_TG_NEW="Android Kernel Build Triggered"
MSG_TG_FAILED="Build failed to compile after"
MSG_TG_CAPTION="Build took"
MSG_HTML_A="Android Device"
MSG_HTML_B="Kernel Version"
MSG_HTML_C="Kernel Variant"
MSG_HTML_D="Host Builder"
MSG_HTML_E="Host Core Count"
MSG_HTML_F="Compiler Used"
MSG_HTML_G="Operating System"
MSG_HTML_H="Build Tag"
MSG_HTML_I="Android"

# lib/updater.sh
# ==============
MSG_UP_NB="Mise à jour de ZenMaxBuilder"
MSG_UP_AK3="Mise à jour de AnyKernel"
MSG_UP_CLANG="Mise à jour de Proton Clang"
MSG_UP_GCC64="Mise à jour de GCC ARM64"
MSG_UP_GCC32="Mise à jour de GCC ARM"

# lib/prompter.sh
# ===============
MSG_ASK_KDIR="Entrez le dossier du noyau (TAB pour l'autocompletion)"
MSG_ERR_KDIR="dossier du noyau invalide"
MSG_ASK_TC="Voulez-vous utiliser le compiler"
MSG_SELECT_TC="Sélectionnez le Compiler à utiliser"
MSG_ERR_SELECT="sélection invalide (utilisez un nombre)"
MSG_ASK_DEV="Entrez le nom de code du téléphone (ex: X00TD)"
MSG_ERR_DEV="code de téléphone invalide"
MSG_ASK_DEF="Sélectionner le fichier defconfig à utiliser"
MSG_ASK_CONF="Voulez-vous éditer le noyau avec menuconfig"
MSG_ASK_CPU="Voulez-vous utiliser tous les Coeurs du CPU"
MSG_ASK_CORES="Entrez le nombre de Coeurs à utiliser"
MSG_ERR_CORES="nombre de coeurs invalide"
MSG_ERR_TOTAL="total"
MSG_ASK_TG="Voulez-vous un retour de compilation sur Telegram"
MSG_ASK_MCLEAN="Voulez-vous lancer un make clean"
MSG_ASK_SAVE_DEF="Voulez-vous sauvegarder et utiliser"
MSG_ASK_USE_DEF="Voulez-vous utiliser le defconfig original"
MSG_START="Lancer la compilation"
MSG_RUN_AGAIN="Recommencer"
MSG_ASK_ZIP="Voulez-vous zipper"
MSG_ASK_IMG="Entrez l'image noyau à utiliser (ex: Image.gz-dtb)"
MSG_ASK_PKG="Paquet non trouvé, voulez-vous installer"
MSG_ERR_DEP="dépendance manquante"
MSG_ERR_MFAIL="la compilation peut échouer"
MSG_ASK_CLONE_TC="Toolchain non trouvée, voulez-vous cloner"
MSG_ERR_TCDIR="dossier toolchain invalide"
MSG_ERR_SEE_CONF="(voir config.sh)"
MSG_ASK_CLONE_AK3="Anykernel non trouvé, voulez-vous cloner"
MSG_ERR_PATH="dossier invalide pour"
MSG_SAVE_USER_CONFIG="Voulez-vous sauvegarder config.sh"

