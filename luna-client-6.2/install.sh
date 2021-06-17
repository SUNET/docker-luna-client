#!/bin/sh
#

case "`echo 'x\c'`" in 'x\c')
                           echo="echo -n"
                           nnl= ;;       
                           
                           x)      
                           echo="echo"      
                           nnl="\c" ;;   
                           
esac


VERSION="5.4.1"
RELEASE="2"

IS_OS_HP_UX=0 
IS_OS_AIX=0

# Will be set to 1 if we are on a debian Linux machine
LINUX_DEBIAN=0

INSTALLED="(installed)"

# displays status messages
STATUS=""

# Used for Luna Products selection
# By default no Luna Product will be installed
LUNA_SA_SELECTED=" "
LUNA_PCI_SELECTED=" "
LUNA_G5_SELECTED=" "
LUNA_REM_BACKUP_HSM_SELECTED=" "

# Used for Luna Components selection
# By default all extra components but SDK will be installed
LUNA_SDK_SELECTED=" "
LUNA_JSP_SELECTED="*"
LUNA_JCPROV_SELECTED="*"
LUNA_DPC_SELECTED="*"
LUNA_SNMP_SELECTED=" "

# Initialize variables
SAVED_LUNA_SDK_SELECTED=" "
SAVED_LUNA_JSP_SELECTED=" "
SAVED_LUNA_JCPROV_SELECTED=" "
SAVED_LUNA_DPC_SELECTED=" "
SAVED_LUNA_SNMP_SELECTED=" "

# Packages list
all_client_pkgs=""
sa_client_pkgs=""
pci_client_pkgs=""
g5_client_pkgs=""
rb_client_pkgs=""
sdk_pkgs=""
jsp_pkgs=""
jcprov_client_pkgs=""
ldpc_client_pkgs=""
snmp_client_pkgs=""

# Used to track if first time getting into Components selection function
first_time_in_components=1

# Flag to know whether it is an update install or not
update_install=0

prompt_yes_no() {
    rsp=""
    while [ "$rsp" != "y" ] && [ "$rsp" != "n" ] && [ "$rsp" != "yes" ] && [ "$rsp" != "no" ]
    do
        $echo "$1 ${nnl}"
        read rsp
    done;
    
    if [ "$rsp" = "y" ] || [ "$rsp" = "yes" ] ; then
        return 0
    fi
    
    return 1
}


display_license() {
    echo "IMPORTANT:  The terms and conditions of use outlined in the software"
    echo "license agreement (Document #008-010005-001_Rev H) shipped with the product"
    echo "(\"License\") constitute a legal agreement between you and SafeNet Inc."
    echo "Please read the License contained in the packaging of this"
    echo "product in its entirety before installing this product."
    echo ""
    echo "Do you agree to the License contained in the product packaging? "
    echo ""
    echo "If you select 'yes' or 'y' you agree to be bound by all the terms"
    echo "and conditions set out in the License."
    echo ""
    echo "If you select 'no' or 'n', this product will not be installed."
    echo ""
    
    prompt_yes_no "(y/n)"
    
    if [ $? -eq 0 ]; then
        echo ""
    else
        echo "You must agree to the license agreement before installing this software."
        echo "The install will now exit."
        exit 1
    fi

    # If Cryptoki package is installed we tell the user to manually uninstall the existing Luna Client first
    check_pkg_installed $CRYPTOKI_PKG
    if [ $? -eq 0 ] ; then
        echo "A version of Luna Client is already installed."
        echo "Please uninstall it first and launch the installation again."
        exit 1
    fi
}

display_install_parameters() {
    echo ""
    $INSTALL_ECHO_E "\t-p <list of Luna products>"
    $INSTALL_ECHO_E "\t-c <list of Luna components|all>  - Optional. Default components are installed if not provided"
    echo ""
    echo "Luna products options"
    echo "   sa     - Luna SA"
    
    if [ $IS_OS_AIX -eq 0 ] ; then
        echo "   pci    - Luna PCI-E"
        if [ $IS_OS_HP_UX -eq 0 ] ; then 
                echo "   g5     - Luna G5"
                echo "   rb     - Luna Remote Backup HSM"
        fi
    fi

    echo ""
    echo "Luna components options"
    echo "   sdk    - Luna SDK"
    echo "   jsp    - Luna JSP (Java)   --> Luna SA, Luna PCI-E and Luna G5 default component"
    echo "   jcprov - Luna JCPROV (Java)   --> Luna SA, Luna PCI-E and Luna G5 default component"
    echo "   ldpc   - Crypto Command Center Provisioning Client   --> Luna SA only default component"
    echo "   snmp   - Luna SNMP subagent"
    echo ""
}

display_install_help() {
    case `uname -s` in
       [lL]inux)
           INSTALL_ECHO_E="echo -e"
       ;;

       *)
           INSTALL_ECHO_E="echo"
       ;;
    esac

    echo ""
    echo "usage:"
    $INSTALL_ECHO_E "\tinstall.sh\t- Luna Client install through menu"
    $INSTALL_ECHO_E "\tinstall.sh help\t- Display scriptable install options"
    $INSTALL_ECHO_E "\tinstall.sh all\t- Complete Luna Client install"
    echo ""
    
    INSTALL_OPTION="\tinstall.sh -p [sa"
    if [ $IS_OS_AIX -eq 0 ] ; then
        INSTALL_OPTION="$INSTALL_OPTION|pci"
        if [ $IS_OS_HP_UX -eq 0 ] ; then 
                INSTALL_OPTION="$INSTALL_OPTION|g5|rb"
        fi
    fi
    INSTALL_OPTION="$INSTALL_OPTION] [-c sdk|jsp|jcprov|ldpc|snmp]"
    
    $INSTALL_ECHO_E $INSTALL_OPTION
    display_install_parameters
    echo ""
}

display_usage() {
    echo ""
    echo "Invalid option: $1"
    echo ""
    echo "usage:"
    $INSTALL_ECHO_E "\tinstall.sh\t- Luna Client install through menu"
    $INSTALL_ECHO_E "\tinstall.sh help\t- Display scriptable install options"
    $INSTALL_ECHO_E "\tinstall.sh all\t- Complete Luna Client install"
    echo ""
    
    INSTALL_OPTION="\tinstall.sh -p [sa"
    if [ $IS_OS_AIX -eq 0 ] ; then
        INSTALL_OPTION="$INSTALL_OPTION|pci"
        if [ $IS_OS_HP_UX -eq 0 ] ; then 
                INSTALL_OPTION="$INSTALL_OPTION|g5|rb"
        fi
    fi
    INSTALL_OPTION="$INSTALL_OPTION] [-c sdk|jsp|jcprov|ldpc|snmp]"
    
    $INSTALL_ECHO_E $INSTALL_OPTION

    display_install_parameters
    echo "No parameters: Complete Luna Client install"
    echo "Single parameter: All packages for the selected HSM"
    echo ""
}

confirm_install() {
    echo ""
#    echo "Complete Luna Client will be installed. This includes Luna SA"
    
    
    DISPLAY_OPTION="Complete Luna Client will be installed. This includes Luna SA"
    if [ $IS_OS_AIX -eq 0 ] ; then
        DISPLAY_OPTION="$DISPLAY_OPTION,\nLuna PCI-E"
        if [ $IS_OS_HP_UX -eq 0 ] ; then 
                DISPLAY_OPTION="$DISPLAY_OPTION, Luna G5 AND Luna Remote Backup HSM"
        fi
    fi
    DISPLAY_OPTION="$DISPLAY_OPTION."
    echo $DISPLAY_OPTION
    echo ""
    echo "Select 'yes' or 'y' to proceed with the install."
    echo ""
    echo "Select 'no' or 'n', to cancel this install."
    echo ""

    #prompt_yes_no "Continue (y/n)?"

    if [ $? -eq 0 ]; then
        echo ""
    else
        echo ""
        echo "Run install.sh and select the appropriate feature to install:"
        echo ""
        $INSTALL_ECHO_E "\tinstall.sh all\t- Complete Luna Client install"
        INSTALL_OPTION="\tinstall.sh -p [sa"
        if [ $IS_OS_AIX -eq 0 ] ; then
        INSTALL_OPTION="$INSTALL_OPTION|pci"
            if [ $IS_OS_HP_UX -eq 0 ] ; then 
                INSTALL_OPTION="$INSTALL_OPTION|g5|rb"
            fi
        fi
        INSTALL_OPTION="$INSTALL_OPTION] [-c sdk|jsp|jcprov|ldpc|snmp]"
        
        $INSTALL_ECHO_E $INSTALL_OPTION
        display_install_parameters
        exit 1
    fi
}


get_os_info() {
    
    CMU_PKG="lunacmu"
    SHIM_PKG="libshim"
    CONFIG_PKG="lunaconf"
    VTL_PKG="lunavtl"
    CKDEMO_PKG="ckdemo"
    SALOGIN_PKG="salogin"
    MULTITOKEN_PKG="lunaMT"
    CKLOG_PKG="cklog"
    JAVASAMP_PKG="javaSAMP"
    CKSAMPLE_PKG="lunaSAMP"
    CRYPTOKI_PKG="lunalib"
    CM_PKG="lunacm"
    DIAG_PKG="lunadiag"
    PEDCLIENT_PKG="pedClient"
    LUNAJSP_PKG="lunajsp"
    LUNAJMT_PKG="lunajmt"
    UHD_PKG="uhd"
    VKD_PKG="vkd"
    RBS_PKG="lunarbs"
    JCPROV_PKG="lunajcprov"
    JCPROVSAMP_PKG="jcprovsamples"
    HTLC_PKG="htl_client"
    LUNADPC_PKG="lunadpc"
    LUNA_SNMP_PKG="luna-snmp"
    LUNA_DEST_PATH="/usr/safenet/lunaclient"
    PTA_PKG=""

    case `uname -s` in
        HP-UX)
            INSTALL_ECHO_E="echo"
            INSTALL_ECHO_N="echo -n"
            OSNAME="hpux"
            CRYSTOKI_FILE_SAVE="Chrystoki.conf.depsave"
            MULTITOKEN_PKG="lunamt"
            CKSAMPLE_PKG="lunasamp"
            VKD_PKG="LunaPCI"
            UHD_PKG=""
            RBS_PKG=""
            # not ready for hpux yet
            HTLC_PKG="lunahtlc"
            PTA_PKG=""
            LUNA_SNMP_PKG="lunasnmp"
            LUNA_DEST_PATH="/opt/safenet/lunaclient"

            if [ "`uname -m`" != "ia64" ] ; then
                # HP-UX PA-RISC is no longer supported
                echo "$This OS ($OSNAME) is not supported. Please contact SafeNet support"
                exit 1
            fi
            ;;

       [lL]inux)
            # echo -e does not work on Solaris
            INSTALL_ECHO_E="echo -e"
            # echo -n does not work directly on Solaris
            INSTALL_ECHO_N="echo -n"
            OSNAME="linux"
            if [ -f /etc/debian_version ]; then
                CRYSTOKI_FILE_SAVE="Chrystoki.conf.debsave"
            else
                CRYSTOKI_FILE_SAVE="Chrystoki.conf.rpmsave"
            fi
            CRYPTOKI_PKG="libcryptoki"
            MULTITOKEN_PKG="multitoken"
            CKSAMPLE_PKG="ckSample"
            VTL_PKG="vtl"
            CONFIG_PKG="configurator"
                
            # Get the linux extension if it is not uninstall
            if [ $1 -ne 1 ] ; then
                LINUX_FILE_EXTENSION=`ls ${CRYPTOKI_PKG}* | cut -d. -f4`.rpm
            fi

            # Debian support
            if [ -f /etc/debian_version ]; then
                LINUX_DEBIAN=1
            fi
            ;;

        [sS]unOS)
            INSTALL_ECHO_E="echo"
            INSTALL_ECHO_N="/usr/ucb/echo -n"
            OSNAME="solaris"
            CRYSTOKI_FILE_SAVE="Chrystoki.conf.dssave"
            LUNA_DEST_PATH="/opt/safenet/lunaclient"
            VKD_PKG="lunak4"
            HTLC_PKG="lunahtlc"
            RBS_PKG="rbs"
            UHD_PKG="lunauhd"
            LUNA_SNMP_PKG="lunasnmp"
                
            # If uninstall, query the OS for the package name
            if [ $1 -eq 1 ] ; then
                if ( check_pkg_installed_solaris lunaJSP32x86 ) ; then
                    LUNAJSP_PKG="lunaJSP32x86"
                elif ( check_pkg_installed_solaris lunaJSP64x86 ) ; then
                    LUNAJSP_PKG="lunaJSP64x86"
                elif ( check_pkg_installed_solaris lunaJSP64 ) ; then
                    LUNAJSP_PKG="lunaJSP64"
                elif ( check_pkg_installed_solaris lunaJSP ) ; then
                    LUNAJSP_PKG="lunaJSP"
                else
                    LUNAJSP_PKG=""
                fi
                
                if ( check_pkg_installed_solaris lunaJCPROV32x86 ) ; then
                    JCPROV_PKG="lunaJCPROV32x86"
                elif ( check_pkg_installed_solaris lunaJCPROV64x86 ) ; then
                    JCPROV_PKG="lunaJCPROV64x86"
                elif ( check_pkg_installed_solaris lunaJCPROV64 ) ; then
                    JCPROV_PKG="lunaJCPROV64"
                elif ( check_pkg_installed_solaris lunaJCPROV ) ; then
                    JCPROV_PKG="lunaJCPROV"
                else
                    JCPROV_PKG=""
                fi
            else
                LUNAJSP_PKG=`ls lunaJSP* | cut -d. -f1`
                JCPROV_PKG=`ls lunaJCPROV* | cut -d. -f1`
            fi
            ;;
                
        AIX)
            INSTALL_ECHO_E="echo"
            INSTALL_ECHO_N="echo -n"
            OSNAME="aix"

            # Not currently available on AIX
            UHD_PKG=""
            VKD_PKG=""
            DIAG_PKG=""
            PEDCLIENT_PKG=""
            RBS_PKG=""
            PTA_PKG=""
            LUNA_SNMP_PKG=""

            CRYSTOKI_FILE_SAVE="Chrystoki.conf.bffsave"
            ;;

        *)
            echo "$This OS ($OSNAME) is not supported. Please contact SafeNet support"
            exit 1
            ;;
    esac

    # List of all Luna Client packages to be passed to the uninstall
    client_uninstall_pkgs="${PEDCLIENT_PKG} ${VKD_PKG} ${UHD_PKG} ${SHIM_PKG} ${VTL_PKG} ${CMU_PKG} ${CKDEMO_PKG} ${MULTITOKEN_PKG} ${SALOGIN_PKG} ${CKLOG_PKG} ${DIAG_PKG} ${CM_PKG} ${RBS_PKG} ${PTA_PKG} ${HTLC_PKG} ${JCPROV_PKG} ${LUNADPC_PKG} ${LUNA_SNMP_PKG} ${JAVASAMP_PKG} ${CKSAMPLE_PKG} ${JCPROVSAMP_PKG} ${LUNAJSP_PKG} ${LUNAJMT_PKG} ${CRYPTOKI_PKG} ${CONFIG_PKG}"
    
}

set_packages()
{
    if [ $update_install -eq 1 ] ; then
        base_pkgs=""
    else
        base_pkgs="${CONFIG_PKG} ${CRYPTOKI_PKG} ${SHIM_PKG} ${CM_PKG} ${CMU_PKG} ${CKDEMO_PKG} ${MULTITOKEN_PKG} ${CKLOG_PKG} ${SALOGIN_PKG}"
    fi

    # Luna SA specific packages
    if [ "$LUNA_SA_SELECTED" = "*" ] ; then
        sa_client_pkgs="${VTL_PKG} ${HTLC_PKG} ${PTA_PKG}"
    fi

    # Luna PCI-E specific packages
    if [ "$LUNA_PCI_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" = "*" ] ; then
            # VTL_PKG will be installed with sa_client_pkgs
            pci_client_pkgs="${DIAG_PKG} ${VKD_PKG} ${PEDCLIENT_PKG}"
        else
            pci_client_pkgs="${VTL_PKG} ${DIAG_PKG} ${VKD_PKG} ${PEDCLIENT_PKG}"
        fi
    fi

    # Luna G5 specific packages
    if [ "$LUNA_G5_SELECTED" = "*" ] ; then
        if [ "$LUNA_PCI_SELECTED" = "*" ] ; then
            # VTL_PKG, DIAG_PKG and PEDCLIENT_PKG will be installed with pci_client_pkgs
            g5_client_pkgs="${UHD_PKG}"
        elif [ "$LUNA_SA_SELECTED" = "*" ] ; then
            # VTL_PKG will be installed with sa_client_pkgs
            g5_client_pkgs="${UHD_PKG} ${DIAG_PKG} ${PEDCLIENT_PKG}"
        else
            g5_client_pkgs="${VTL_PKG} ${UHD_PKG} ${DIAG_PKG} ${PEDCLIENT_PKG}"
        fi
    fi

    # Luna Remote Backup HSM specific packages
    # If no other product was selected only Remote Backup HSM tools and driver (G5) should be installed
    if [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" != "*" ] && [ "$LUNA_PCI_SELECTED" != "*" ] && [ "$LUNA_G5_SELECTED" != "*" ] ; then
            base_pkgs="${CONFIG_PKG} ${CRYPTOKI_PKG} ${CM_PKG} ${CKLOG_PKG}"
            rb_client_pkgs="${UHD_PKG} ${RBS_PKG} ${DIAG_PKG} ${PEDCLIENT_PKG}"
        elif [ "$LUNA_PCI_SELECTED" = "*" ] ; then
            if [ "$LUNA_G5_SELECTED" != "*" ] ; then
                rb_client_pkgs="${UHD_PKG} ${RBS_PKG}"
            else
                rb_client_pkgs="${RBS_PKG}"
            fi
        elif [ "$LUNA_G5_SELECTED" = "*" ] ; then
            rb_client_pkgs="${RBS_PKG}"
        elif [ "$LUNA_SA_SELECTED" = "*" ] ; then
            rb_client_pkgs="${UHD_PKG} ${RBS_PKG} ${DIAG_PKG} ${PEDCLIENT_PKG}"
        fi
    fi

    # Set packages to "" when only installing products under which they are not supported
    if [ "$LUNA_SDK_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" = "*" ] || [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] ; then
            sdk_pkgs="${JAVASAMP_PKG} ${CKSAMPLE_PKG} ${JCPROVSAMP_PKG}"
        else
            sdk_pkgs=""
        fi
    fi

    if [ "$LUNA_JSP_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" = "*" ] || [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] ; then
            jsp_pkgs="${LUNAJSP_PKG} ${LUNAJMT_PKG}"
        else
            jsp_pkgs=""
        fi
    fi

    if [ "$LUNA_JCPROV_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" = "*" ] || [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] ; then
            jcprov_client_pkgs="${JCPROV_PKG}"
        else
            jcprov_client_pkgs=""
        fi
    fi

    if [ "$LUNA_DPC_SELECTED" = "*" ] ; then
        if [ "$LUNA_SA_SELECTED" = "*" ] ; then
            ldpc_client_pkgs="${LUNADPC_PKG}"
        else
            ldpc_client_pkgs=""
        fi
    fi

    if [ "$LUNA_SNMP_SELECTED" = "*" ] ; then
        if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
            snmp_client_pkgs="${LUNA_SNMP_PKG}"
        else
            snmp_client_pkgs=""
        fi
    fi

    # List of Luna Client packages to be installed based on menu selections or script options
    client_pkgs="$base_pkgs $sa_client_pkgs $pci_client_pkgs $g5_client_pkgs $rb_client_pkgs $sdk_pkgs $jsp_pkgs $jcprov_client_pkgs $ldpc_client_pkgs $snmp_client_pkgs"
}

check_pkg_installed() {
    check_pkg_installed_$OSNAME $1
    return $?
}

remove_pkg() {
    echo "Removing current version of $1"
    remove_pkg_$OSNAME $1
    return $?
}

add_pkg() {
    echo "Adding new version of $2"
    CWD="`pwd`"
    echo $CWD
    cd "$1"
    add_pkg_$OSNAME $2
    result=$?
    cd "$CWD"
    return $result
}

remove_driver()
{
    if [ "$OSNAME" = "linux" ] ; then
        if ( lsmod | grep $1 > /dev/null ) ; then
            rmmod $1 &> /dev/null
        fi
        
    elif [ "$OSNAME" = "solaris" ] ; then
        if ( modinfo | grep $1 > /dev/null ) ; then
            DRIVER_ID=`modinfo -c | grep $1 | awk '{print $1}'`
            rem_drv $1 > /dev/null 2>&1
            update_drv $1 > /dev/null 2>&1
            modunload -i $DRIVER_ID > /dev/null
        fi
        
    elif [ "$OSNAME" = "hpux" ] ; then
        if ( /usr/sbin/lsdev | grep $1 > /dev/null ) ; then
            /usr/sbin/kcmodule -s $1=uninstall> /dev/null 2>&1
        fi
    fi
    
    return $?
}

check_remove_driver() {
    
    remove_driver $1
    if [ $? -ne 0 ] ; then
        echo "Aborting Luna Client install...."
        echo "Luna $2 driver ($1) is in use."
        echo "Please stop the application using it or restart the machine."
        # Uninstall what got uninstalled
        uninstall_client_on_error
        exit 1
    fi
        
}

install_pkg() {

    if [ "$2" = "uhd" ] || [ "$2" = "vkd" ] || [ "$2" = "lunauhd" ] || [ "$2" = "lunak4" ] || [ "$2" = "LunaPCI" ] ; then
        
        # Checking the Driver Name
        if [ "$2" = "vkd" ] || [ "$2" = "lunak4" ] || [ "$2" = "LunaPCI" ] ; then
            DEVICE_NAME="PCI-E"
        elif [ "$2" = "uhd" ] || [ "$2" = "lunauhd" ]; then
            DEVICE_NAME="G5"
        fi
        
        # Checking Luna G5/PCI driver (uhd or vkd) is in use
        if [ "$OSNAME" = "hpux" ] ; then
            DRIVER_NAME="vkd"
            check_remove_driver $DRIVER_NAME $DEVICE_NAME
        else
            check_remove_driver $2 $DEVICE_NAME 
        fi
        
    fi   
    
    if [ "$2" = "uhd" ] ; then 
        if [ "$OSNAME" = "linux" ] ; then
            # Install Linux UHD driver
            install_g5_linux_driver
        fi

    elif [ "$2" = "vkd" ] ; then
        if [ "$OSNAME" = "linux" ] ; then
            # Install VKD driver
            install_pci_linux_driver
        fi
        
    else
        add_pkg $1 $2
        if [ $? -ne 0 ]; then
            echo "Error: Failed to add package $2. Please contact SafeNet support for help."
            # Uninstall what got uninstalled
            uninstall_client_on_error
            exit 1
        fi
    fi
      
}

uninstall_pkg() {
    if ( check_pkg_installed $1 ) ; then
        remove_pkg $1
        if [ $? -ne 0 ]; then
            echo "Error: Failed to remove package $1$2. Please contact SafeNet support for help."
            exit 1
        fi
    fi
}

install_multi_pkg() {
    echo ""
    echo "Installing $1..."
    
    # Copy the uninstall script right at the beginning.
    # Note: Install path created to copy the uninstall script
    # will be deleted if no package was installed.
    copy_uninstall_script

    for pkg in $3
    do
        install_pkg $2 $pkg
    done
    return 0
    echo "Installing done."

    return 1
}

uninstall_multi_pkg() {
    
    # Only ask question if $1 is not empty
    if [ "$1" != "" ] ; then
        echo ""
        prompt_yes_no "Are you sure you want to uninstall $1 features specified? (y/n) "

        if [ $? -eq 1 ] ; then
            return 1
        fi
    fi
    

    # Uninstall packages
    uninst_pkgs_list=$2
    for pkg in $uninst_pkgs_list
    do
        uninstall_pkg $pkg
    done;

    return 0
}

check_pkg_installed_linux() {
    if [ $LINUX_DEBIAN -eq 0 ] ; then
        rpm -q --quiet $1
    else
        # Convert the package name to lowercase since alien
        # sets the name to lowercase during the install
        new_pkg=`echo $1 | awk '{ print tolower($1); }'`

        # htl_client is converted to htl-client by alien command during the install
        if [ "$new_pkg" = $HTLC_PKG ] ; then
            new_pkg="htl-client"
        fi

        eval dpkg -l $new_pkg 2>/dev/null | tail -1 | cut -d" " -f1 | grep -q -e ".i"
    fi

    return $? 
}

remove_pkg_linux() {
    if [ $LINUX_DEBIAN -eq 0 ] ; then
        rpm -e $pkg
    else
        # Convert the package name to lowercase since alien
        # sets the name to lowercase during the install
        new_pkg=`echo $pkg | awk '{ print tolower($1); }'`
        if [ "$new_pkg" = $CRYPTOKI_PKG ] || [ "$new_pkg" = $RBS_PKG ] || [ "$new_pkg" = $VTL_PKG ] || [ "$new_pkg" = $CONFIG_PKG ] ; then
            # We just remove the packages without --purge option to leave some directories in place
            PKG_RM_CMD="dpkg -r"
        else
            # --purge will remove all files and directories installed by the package
            PKG_RM_CMD="dpkg --purge"

            # htl_client is converted to htl-client by alien command during the install
            if [ "$new_pkg" = $HTLC_PKG ] ; then
                new_pkg="htl-client"
            fi
        fi
        $PKG_RM_CMD $new_pkg
    fi

    return $?
}

add_pkg_linux() {
    version=${VERSION}-${RELEASE}

    if [ $LINUX_DEBIAN -eq 0 ] ; then
        if [ $1 = $LUNADPC_PKG ] ; then
            LUNADPC_RPM=`ls $LUNADPC_PKG*`
            rpm -ivh $LUNADPC_RPM
        else
            rpm -ivh $1-$version.${LINUX_FILE_EXTENSION}
        fi
    else
        # Installing on Debian machine
        if [ $1 = $LUNADPC_PKG ] ; then
            LUNADPC_RPM=`ls $LUNADPC_PKG*`
            alien -k -i --scripts $LUNADPC_RPM
        else
            alien -k -i --scripts $1-$version.${LINUX_FILE_EXTENSION}
        fi
    fi

    return $?
}

check_pkg_installed_solaris() {
    pkginfo -q $1
    return $? 
}

add_pkg_solaris() {
    # -a will use nocheck file to avoid prompts druring the package install.
    # all_input contains one line with the word "all" needed for the first install prompt
    # which cannot be be bypassed using the -a option.

    pkgadd -a noask -d $1.ds < all_input
    return $? 
}

remove_pkg_solaris() {
    yes | pkgrm $pkg
    return $?
}

check_pkg_installed_aix() {
    lslpp -L | grep $1 >/dev/null
    return $? 
}

add_pkg_aix() {
    installp -a -d $pkg.bff all
    return $?
}

remove_pkg_aix() {
    installp -u $pkg
    return $?
}

check_pkg_installed_hpux() {
    swlist $1 2>/dev/null 1>/dev/null
    return $? 
}

add_pkg_hpux() {
    swinstall -v -s "`pwd`/$1.dep" $1
    return $?
}

remove_pkg_hpux() {
    swremove -v $1
    return $?
}

# Checks whether PCI or/and G5 drivers are loaded if they got installed
# After a maximum number of unsuccessful tries we display a message that the
# driver is installed but not loaded.
check_drivers_loaded() {
    drivers_list="vkd uhd"
    vkd_driver_loaded=0
    uhd_driver_loaded=0

    for driver in $drivers_list
    do
        if ( check_pkg_installed $driver ) ; then
            # $driver package is installed so check if it is loaded
            # Found that usbcore line (for uhd) gets returns as well as follow so we extract it
            # usbcore               123271  4 uhd,uhci_hcd,ehci_hcd
            lsmod | grep $driver | grep -v usbcore
            
        fi
    done
}

install_client() {
    # Install clients
    install_multi_pkg "the Luna Client ${VERSION}-${RELEASE}" "." "$1"
    if [ $? -ne 0 ] ; then
        echo "Operation cancelled by user..."
        exit 1
    fi
    
    echo ""
    echo "Installation of the Luna Client ${VERSION}-${RELEASE} completed."
    echo ""
}

uninstall_client() {
    # Uninstall clients
    uninstall_multi_pkg "" "$1"
    if [ $? -ne 0 ] ; then
        echo "Operation canceled by user..."
        exit 1
    fi
    
    # Cleanup leftover folders  
    rm -fr $LUNA_DEST_PATH/lib
    rm -fr $LUNA_DEST_PATH/sbin
    rm -fr $LUNA_DEST_PATH/htl
    rm -fr $LUNA_DEST_PATH/jsp
    rm -fr $LUNA_DEST_PATH/jcprov
    rm -fr $LUNA_DEST_PATH/samples
    rm -rf $LUNA_DEST_PATH/pcidriver
    rm -rf $LUNA_DEST_PATH/g5driver
    rm -rf $LUNA_DEST_PATH/snmp

    if [ $LINUX_DEBIAN -eq 1 ] ; then
        rm -fr $LUNA_DEST_PATH/debian_pkgs
    fi
    
    # Moving error output to /dev/null, Solaris and HP-UX produces error output if script tries to remove bin directory in the path of the current working directory. 
    if [ "$OSNAME" = "solaris" ] || [ "$OSNAME" = "hpux" ] || [ "$OSNAME" = "aix" ]; then
        rm -fr $LUNA_DEST_PATH/bin> /dev/null 2>&1
    else
        rm -fr $LUNA_DEST_PATH/bin
    fi

    echo ""
    echo "Uninstall of the Luna Client ${VERSION}-${RELEASE} completed."
    echo ""
}

save_conf_file() {
    # save previous version of Chrystoki.conf
    if [ -f /etc/Chrystoki.conf ] ; then
        prompt_yes_no "Would you like to backup your Chrystoki.conf file? (y/n)"
        if [ $? -eq 0 ] ; then 
            cp /etc/Chrystoki.conf /etc/${CRYSTOKI_FILE_SAVE}
            echo "It has been saved as /etc/${CRYSTOKI_FILE_SAVE}"
            echo
        fi
    fi
}

check_random() {
    # Check and see if /var/run/egd-pool or /dev/random exists
    # Since /dev/random is better we check for it first
    if [ ! -r "/dev/random" ] ; then
       if [ ! -r "/var/run/egd-pool" ] ; then
          echo "Error: /var/run/egd-pool and /dev/random not found.  Please check the documentation for instructions on installing /var/run/egd-pool or /dev/random."
          echo "       The installation will now abort."
          exit 1
       fi
    fi
}

is_any_pkg_installed() {

    for pkg in $all_client_pkgs
    do
        check_pkg_installed $pkg
        if [ $? -eq 0 ] ; then
            return 0
        fi
    done;
    
    return 1
}

are_all_pkgs_installed() {

    for pkg in $all_client_pkgs
    do
        check_pkg_installed $pkg
        if [ $? -ne 0 ] ; then
            return 1
        fi
    done;
    
    return 0
}

install_g5_linux_driver() {
    # Install G5 driver
    SCRIPT_DIR=`pwd`

    # Uninstall any installed version of G5 driver
    if [ $LINUX_DEBIAN -eq 0 ] ; then
        if ( rpm -q --quiet uhd-${VERSION} ) ; then
            if ( rpm -e uhd-${VERSION} ) ; then
                echo "Uninstalled existing uhd driver."
            fi
        fi
    else
        if ( eval dpkg -l uhd 2>/dev/null | tail -1 | cut -d" " -f1 | grep -q -e ".i" ) ; then
            if ( dpkg --purge uhd ) ; then
                echo "Uninstalled existing uhd driver."
            fi
        fi
    fi

    if [ -e "$LUNA_DEST_PATH/g5driver" ] ; then
        rm -rf $LUNA_DEST_PATH/g5driver
    fi

    if [ ! -r "$LUNA_DEST_PATH/g5driver" ]; then
        mkdir $LUNA_DEST_PATH/g5driver
    fi

    # For installing on various arch
    BITNESS=`getconf LONG_BIT`
    if [ $BITNESS -eq 32 ] ; then
        ARCH="i386"
    else
        ARCH="x86_64"
    fi
    
    cp uhd-${VERSION}-*.src.rpm $LUNA_DEST_PATH/g5driver/
    cd $LUNA_DEST_PATH/g5driver
    rpmbuild --rebuild --target $ARCH uhd-${VERSION}-*.src.rpm
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build G5 driver. Please contact SafeNet support for help."
        cd $SCRIPT_DIR
        # Uninstall what got uninstalled
        uninstall_client_on_error
        exit 1
    fi

    if [ $LINUX_DEBIAN -eq 0 ] ; then
        rpm -i ./$ARCH/uhd-${VERSION}-*.$ARCH.rpm
    else
        alien -k -i --scripts ./$ARCH/uhd-${VERSION}-*.$ARCH.rpm
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install G5 driver. Please contact SafeNet support for help."
        cd $SCRIPT_DIR
        # Uninstall what got uninstalled
        uninstall_client_on_error
        exit 1
    fi
    
    cd $SCRIPT_DIR
    
    echo ""
    echo "Installation of the Luna G5 ${VERSION}-${RELEASE} driver completed."
    echo ""
}

install_pci_linux_driver() {
    # Install PCI driver
    SCRIPT_DIR=`pwd`

    # Uninstall any installed version of PCI-E driver
    if [ $LINUX_DEBIAN -eq 0 ] ; then
        if ( rpm -q --quiet vkd-${VERSION} ) ; then
            if ( rpm -e vkd-${VERSION} ) ; then
                echo "Uninstalled existing vkd driver." 
            fi
        fi
    else
        if ( eval dpkg -l vkd 2>/dev/null | tail -1 | cut -d" " -f1 | grep -q -e ".i" ) ; then
            if ( dpkg --purge vkd ) ; then
                echo "Uninstalled existing vkd driver."
            fi
        fi
    fi

    if [ -e "$LUNA_DEST_PATH/pcidriver" ] ; then
        rm -rf $LUNA_DEST_PATH/pcidriver
    fi

    if [ ! -r "$LUNA_DEST_PATH/pcidriver" ]; then
        mkdir $LUNA_DEST_PATH/pcidriver
    fi

    # For installing on various arch
    BITNESS=`getconf LONG_BIT`
    if [ $BITNESS -eq 32 ] ; then
        ARCH="i386"
    else
        ARCH="x86_64"
    fi

    cp vkd-${VERSION}-*.src.rpm $LUNA_DEST_PATH/pcidriver/
    cd $LUNA_DEST_PATH/pcidriver
    rpmbuild --rebuild --target $ARCH vkd-${VERSION}-*.src.rpm
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Luna PCI-E driver. Please contact SafeNet support for help."
        cd $SCRIPT_DIR
        # Uninstall what got uninstalled
        uninstall_client_on_error
        exit 1
    fi

    if [ $LINUX_DEBIAN -eq 0 ] ; then
        rpm -i ./$ARCH/vkd-${VERSION}-*.$ARCH.rpm
    else
        alien -k -i --scripts ./$ARCH/vkd-${VERSION}-*.$ARCH.rpm
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Luna PCI-E driver. Please contact SafeNet support for help."
        cd $SCRIPT_DIR
        # Uninstall what got uninstalled
        uninstall_client_on_error
        exit 1
    fi
    
    cd $SCRIPT_DIR
    
    echo ""
    echo "Installation of the Luna PCI ${VERSION}-${RELEASE} driver completed."
    echo ""
}


copy_uninstall_script()
{
    # Copy uninstall script if installing a package
    mkdir -p $LUNA_DEST_PATH/bin 2>/dev/null
    # Note that file names are changing.
    # Install becomes common so a user does not try to install from an already installed product
    # common becomes uninstall.sh so a user does not try to uninstall from the install (source) directory
    cp -f install.sh $LUNA_DEST_PATH/bin/common
    cp -f common $LUNA_DEST_PATH/bin/uninstall.sh
    chmod +x $LUNA_DEST_PATH/bin/uninstall.sh

    if [ $LINUX_DEBIAN -eq 1 ] ; then
        linux_debian_install_setup
    fi
}

# Called when an error has occured during the install to uninstall whatever got installed
uninstall_client_on_error()
{
    if [ "$client_uninstall_pkgs" != "" ] ; then
        uninstall_client "$client_uninstall_pkgs" > /dev/null 2>&1
    fi
}

prompt_for_products()
{
    product=$1

    # Check if some Luna Products are already installed and mark them as such
    # If cryptoki is not installed we know that nothing is installed
    # Set products packages list just to check if they are already installed and then clear them
    sa_client_pkgs="${VTL_PKG} ${HTLC_PKG}"
    pci_client_pkgs="${VTL_PKG} ${VKD_PKG} ${DIAG_PKG}"
    g5_client_pkgs="${VTL_PKG} ${UHD_PKG} ${DIAG_PKG}"
    rb_client_pkgs="${UHD_PKG} ${RBS_PKG}"
    LUNA_SA_INSTALLED=""
    LUNA_PCI_INSTALLED=""
    LUNA_G5_INSTALLED=""
    LUNA_RP_INSTALLED=""
    LUNA_RB_INSTALLED=""

    check_pkg_installed $CRYPTOKI_PKG
    if [ $? -eq 0 ] ; then
        update_install=1
        # Check if Luna SA is already installed
        all_client_pkgs=$sa_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_SA_INSTALLED="$INSTALLED"
        fi

        # Check if Luna PCI is already installed
        all_client_pkgs=$pci_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_PCI_INSTALLED="$INSTALLED"
        fi

        # Check if Luna G5 is already installed
        all_client_pkgs=$g5_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_G5_INSTALLED="$INSTALLED"
        fi

        # Check if Luna Remote Backup HSM is already installed
        all_client_pkgs=$rb_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_RB_INSTALLED="$INSTALLED"
        fi
    fi

    # Clear all products packages list
    sa_client_pkgs=""
    pci_client_pkgs=""
    g5_client_pkgs=""
    rb_client_pkgs=""
    all_client_pkgs=""

    case $product in
        "1")
            if [ "$LUNA_SA_INSTALLED" = "" ] ; then
                if [ "$LUNA_SA_SELECTED" = "*" ] ; then
                    LUNA_SA_SELECTED=" "
                else
                    LUNA_SA_SELECTED="*"
                fi
            fi
            ;;

        "2")
            if [ "$LUNA_PCI_INSTALLED" = "" ] ; then
                if [ "$LUNA_PCI_SELECTED" = "*" ] ; then
                    LUNA_PCI_SELECTED=" "
                else
                    LUNA_PCI_SELECTED="*"
                fi
            fi
            ;;

        "3")
            if [ "$LUNA_G5_INSTALLED" = "" ] ; then
                if [ "$LUNA_G5_SELECTED" = "*" ] ; then
                    LUNA_G5_SELECTED=" "
                else
                    LUNA_G5_SELECTED="*"
                fi
            fi
            ;;

        "4")
            if [ "$LUNA_RB_INSTALLED" = "" ] ; then
                if [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
                    LUNA_REM_BACKUP_HSM_SELECTED=" "
                else
                    LUNA_REM_BACKUP_HSM_SELECTED="*"
                fi
            fi
            ;;

    esac

    clear
    echo "Products"
    echo "Choose Luna Products to be installed"
    echo
    echo " ${LUNA_SA_SELECTED}[1]: Luna SA $LUNA_SA_INSTALLED"
    if [ $IS_OS_AIX -eq 0 ] ; then
        echo
        echo " ${LUNA_PCI_SELECTED}[2]: Luna PCI-E $LUNA_PCI_INSTALLED"
        if [ $IS_OS_HP_UX -eq 0 ] ; then 
            echo
            echo " ${LUNA_G5_SELECTED}[3]: Luna G5 $LUNA_G5_INSTALLED"
            echo
            echo " ${LUNA_REM_BACKUP_HSM_SELECTED}[4]: Luna Remote Backup HSM $LUNA_RB_INSTALLED"
        fi
    fi
    echo
    echo "  [N|n]: Next"
    echo
    echo "  [Q|q]: Quit"
    echo
    if [ "$STATUS" != "" ] ; then
       echo "$STATUS"
       echo
    fi
    #$INSTALL_ECHO_N " Enter selection: "
    $echo " Enter selection: ${nnl} "
}

prompt_for_components()
{
    component=$1
    # Count of selectable components after the products selection
    components_count=0

    # Check if some Luna Products are already installed and mark them as such
    # If cryptoki is not installed we know that nothing is installed
    # Set products packages list just to check if they are already installed and then clear them
    sdk_pkgs="${JAVASAMP_PKG} ${CKSAMPLE_PKG} ${JCPROVSAMP_PKG}"
    jsp_pkgs="${LUNAJSP_PKG} ${LUNAJMT_PKG}"
    jcprov_client_pkgs="${JCPROV_PKG}"
    ldpc_client_pkgs="${LUNADPC_PKG}"
    snmp_client_pkgs="${LUNA_SNMP_PKG}"
    LUNA_SDK_INSTALLED=""
    LUNA_JSP_INSTALLED=""
    LUNA_JCPROV_INSTALLED=""
    LUNA_DPC_INSTALLED=""
    LUNA_SNMP_INSTALLED=""

    check_pkg_installed $CRYPTOKI_PKG
    if [ $? -eq 0 ] ; then
        update_install=1
        # Check if Luna SDK is already installed
        all_client_pkgs=$sdk_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_SDK_INSTALLED="$INSTALLED"
        fi

        # Check if Luna JSP is already installed
        all_client_pkgs=$jsp_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_JSP_INSTALLED="$INSTALLED"
        fi

        # Check if Luna JCPROV is already installed
        all_client_pkgs=$jcprov_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_JCPROV_INSTALLED="$INSTALLED"
        fi

        # Check if Crypto Command Center Provisioning Client is already installed
        all_client_pkgs=$ldpc_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_DPC_INSTALLED="$INSTALLED"
        fi

        # Check if Luna SNMP subagent is already installed
        all_client_pkgs=$snmp_client_pkgs
        are_all_pkgs_installed
        if [ $? -eq 0 ] ; then
            LUNA_SNMP_INSTALLED="$INSTALLED"
        fi
    fi

    # Clear all components packages list
    sdk_pkgs=""
    jsp_pkgs=""
    jcprov_client_pkgs=""
    ldpc_client_pkgs=""
    snmp_client_pkgs=""
    all_client_pkgs=""

    if [ $first_time_in_components -eq 1 ] ; then
        # When coming to components selection for the first time with components already installed we need to clear the default selection on installed components
        if [ "$LUNA_SDK_INSTALLED" != "" ] ; then
            LUNA_SDK_SELECTED=" "
        fi
        if [ "$LUNA_JSP_INSTALLED" != "" ] ; then
            LUNA_JSP_SELECTED=" "
        fi
        if [ "$LUNA_JCPROV_INSTALLED" != "" ] ; then
            LUNA_JCPROV_SELECTED=" "
        fi
        if [ "$LUNA_DPC_INSTALLED" != "" ] ; then
            LUNA_DPC_SELECTED=" "
        fi
        if [ "$LUNA_SNMP_INSTALLED" != "" ] ; then
            LUNA_SNMP_SELECTED=" "
        fi
    elif [ $first_time_in_components -gt 2 ] ; then
        LUNA_SDK_SELECTED="$SAVED_LUNA_SDK_SELECTED"
        LUNA_JSP_SELECTED="$SAVED_LUNA_JSP_SELECTED"
        LUNA_JCPROV_SELECTED="$SAVED_LUNA_JCPROV_SELECTED"
        LUNA_DPC_SELECTED="$SAVED_LUNA_DPC_SELECTED"
        LUNA_SNMP_SELECTED="$SAVED_LUNA_SNMP_SELECTED"
        LUNA_SNMP_SELECTED="$SAVED_LUNA_SNMP_SELECTED"
    fi

    case $component in
        "1")
            if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_SA_SELECTED" = "*" ] ; then
                if [ "$LUNA_SDK_INSTALLED" = "" ] ; then
                    if [ "$LUNA_SDK_SELECTED" = "*" ] ; then
                        LUNA_SDK_SELECTED=" "
                    else
                        LUNA_SDK_SELECTED="*"
                    fi
                else
                    LUNA_SDK_SELECTED=" "
                fi
            else
                # Right now only Remote Backup HSM product supports only one product.
                # So the only component to display is Luna SNMP subagent
                if [ "$LUNA_SNMP_INSTALLED" = "" ] ; then
                    if [ "$LUNA_SNMP_SELECTED" = "*" ] ; then
                        LUNA_SNMP_SELECTED=" "
                    else
                        LUNA_SNMP_SELECTED="*"
                    fi
                else
                    LUNA_SNMP_SELECTED=" "
                fi
            fi
            ;;

        "2")
            if [ "$LUNA_JSP_INSTALLED" = "" ] ; then
                if [ "$LUNA_JSP_SELECTED" = "*" ] ; then
                    LUNA_JSP_SELECTED=" "
                else
                    LUNA_JSP_SELECTED="*"
                fi
            else
                LUNA_JSP_SELECTED=" "
            fi
            ;;

        "3")
            if [ "$LUNA_JCPROV_INSTALLED" = "" ] ; then
                if [ "$LUNA_JCPROV_SELECTED" = "*" ] ; then
                    LUNA_JCPROV_SELECTED=" "
                else
                    LUNA_JCPROV_SELECTED="*"
                fi
            else
                LUNA_JCPROV_SELECTED=" "
            fi
            ;;

        "4")
            if [ "$LUNA_SA_SELECTED" = "*" ] ; then
                if [ "$LUNA_DPC_INSTALLED" = "" ] ; then
                    if [ "$LUNA_DPC_SELECTED" = "*" ] ; then
                        LUNA_DPC_SELECTED=" "
                    else
                        LUNA_DPC_SELECTED="*"
                    fi
                else
                    LUNA_DPC_SELECTED=" "
                fi
            elif [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] ; then
                if [ "$LUNA_SNMP_INSTALLED" = "" ] ; then
                    if [ "$LUNA_SNMP_SELECTED" = "*" ] ; then
                        LUNA_SNMP_SELECTED=" "
                    else
                        LUNA_SNMP_SELECTED="*"
                    fi
                else
                    LUNA_SNMP_SELECTED=" "
                fi
            fi
            ;;

        "5")
            if [ "$LUNA_SA_SELECTED" = "*" ] && ( [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ) ; then
                if [ "$LUNA_SNMP_INSTALLED" = "" ] ; then
                    if [ "$LUNA_SNMP_SELECTED" = "*" ] ; then
                        LUNA_SNMP_SELECTED=" "
                    else
                        LUNA_SNMP_SELECTED="*"
                    fi
                else
                    LUNA_SNMP_SELECTED=" "
                fi
            fi
            ;;

    esac

    first_time_in_components=`expr $first_time_in_components + 1`

    # Save the default components previous selection values
    SAVED_LUNA_SDK_SELECTED="$LUNA_SDK_SELECTED"
    SAVED_LUNA_JSP_SELECTED="$LUNA_JSP_SELECTED"
    SAVED_LUNA_JCPROV_SELECTED="$LUNA_JCPROV_SELECTED"
    SAVED_LUNA_DPC_SELECTED="$LUNA_DPC_SELECTED"
    SAVED_LUNA_SNMP_SELECTED="$LUNA_SNMP_SELECTED"
    SAVED_LUNA_SNMP_SELECTED="$LUNA_SNMP_SELECTED"

    clear
    echo "Advanced"
    echo "Choose Luna Components to be installed"
    # If only Luna Remote Backup HSM is the only selected product then only Luna SNMP subagent should be displayed
    if [ "$LUNA_SA_SELECTED" = "*" ] || [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] ; then
        echo
        components_count=`expr $components_count + 1`
        echo " ${LUNA_SDK_SELECTED}[$components_count]: Luna Software Development Kit (SDK) $LUNA_SDK_INSTALLED"
        echo
        components_count=`expr $components_count + 1`
        echo " ${LUNA_JSP_SELECTED}[$components_count]: Luna JSP (Java) $LUNA_JSP_INSTALLED"
        echo
        components_count=`expr $components_count + 1`
        echo " ${LUNA_JCPROV_SELECTED}[$components_count]: Luna JCProv (Java) $LUNA_JCPROV_INSTALLED"
        if [ "$LUNA_SA_SELECTED" = "*" ] ; then
            echo
            components_count=`expr $components_count + 1`
            echo " ${LUNA_DPC_SELECTED}[$components_count]: Crypto Command Center Provisioning Client $LUNA_DPC_INSTALLED"
        fi
    fi
    if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
        echo
        components_count=`expr $components_count + 1`
        echo " ${LUNA_SNMP_SELECTED}[$components_count]: Luna SNMP subagent $LUNA_SNMP_INSTALLED"
    fi
    echo
    echo "  [B|b]: Back to Products selection"
    echo
    echo "  [I|i]: Install"
    echo
    echo "  [Q|q]: Quit"
    echo
    #echo " Enter selection: "
    $echo " Enter selection: ${nnl} "
}

select_luna_products_and_components()
{
option=""
product_selected=0

# user must select at least one product before they can
# select individual components
while [ $product_selected -ne 1 ]
do
    prompt_for_products "$option"
    read option
    STATUS=""

    if [ "$option" = "q" ] || [ "$option" = "Q" ] ; then
        prompt_yes_no "Abort installation? (y/n) "
        if [ $? -eq 0 ] ; then
            exit 1
        fi
    fi
    
    if [ $IS_OS_AIX -eq 1 ]; then
        LUNA_PCI_SELECTED=" "
        if [ $IS_OS_HP_UX -eq 1 ]; then
            LUNA_G5_SELECTED=" "
            LUNA_REM_BACKUP_HSM_SELECTED=" "
        fi
    fi
    
    if [ "$option" = "n" ] || [ "$option" = "N" ] ; then
        product_selected=1
        # If no Luna products are installed then at least one must be selected in order to move to components selection
        if [ "$LUNA_SA_INSTALLED" = "" ] && [ "$LUNA_PCI_INSTALLED" = "" ] && [ "$LUNA_G5_INSTALLED" = "" ] && [ "$LUNA_RB_INSTALLED" = "" ] ; then
            if [ "$LUNA_SA_SELECTED" = " " ] && [ "$LUNA_PCI_SELECTED" = " " ] && [ "$LUNA_G5_SELECTED" = " " ] && [ "$LUNA_REM_BACKUP_HSM_SELECTED" = " " ] ; then
                STATUS="*** At least one product must be selected."
                product_selected=0
            fi
        fi
    fi
done;

option=""
while  [ "$option" != "b" ] && [ "$option" != "B" ] && [ "$option" != "i" ] && [ "$option" != "I" ]
do
    if [ "$option" = "q" ] || [ "$option" = "Q" ] ; then
        prompt_yes_no "Abort installation? (y/n) "
        if [ $? -eq 0 ] ; then
            exit 1
        fi
    fi

    prompt_for_components "$option"
    read option
done;
}

# Products and components list passed in to scriptable install
products_list=""
components_list=""
scriptable_get_products_and_components()
{
args="$1"
products=0
components=0

for arg in $args
do
    if [ "$arg" = "-p" ] ; then
        products=1
        components=0
    elif [ "$arg" = "-c" ] ; then
        components=1
        products=0
    elif [ $products -eq 1 ] ; then
        if [ "$products_list" = "" ] ; then
            products_list="$arg"
        else
            products_list="$products_list $arg"
        fi
    elif [ $components -eq 1 ] ; then
        if [ "$components_list" = "" ] ; then
            components_list="$arg"
        else
            components_list="$components_list $arg"
        fi
    fi
done

new_product_list=""
for product in $products_list
do
    case "$product" in
        sa|SA)
            new_product_list="$new_product_list $product"
        ;;

        pci|PCI)
            if [ $IS_OS_AIX -eq 0 ]; then
                new_product_list="$new_product_list $product"
            fi
            
        ;;

        g5|G5)
            if [ $IS_OS_AIX -eq 0 ] && [ $IS_OS_HP_UX -eq 0 ] ; then
                new_product_list="$new_product_list $product"
            fi
        ;;

        rb|RB)
                if [ $IS_OS_AIX -eq 0 ] && [ $IS_OS_HP_UX -eq 0 ] ; then
                new_product_list="$new_product_list $product"
                        fi
        ;;
    esac
done
products_list="$new_product_list"

if [ "$products_list" = "" ] ; then
    echo "At least one product should be specified."
    display_install_help
    exit 1
fi
}


# If on Linux debian machine we copy the rpms to a directory on local drive
# so that we can use alien command
# We first check whether all necessary commands are installed
linux_debian_install_setup()
{
    which alien 2>/dev/null 1>&2
    if [ $? -ne 0 ] ; then
        echo "alien command was not found."
        echo "Please install alien package and launch the install again."
        exit 1
    fi

    which rpmbuild 2>/dev/null 1>&2
    if [ $? -ne 0 ] ; then
        echo "rpmbuild command was not found."
        echo "Please install rpmbuild package and launch the install again."
        exit 1
    fi

    mkdir -p $LUNA_DEST_PATH/debian_pkgs 2>/dev/null
    cp * $LUNA_DEST_PATH/debian_pkgs
    cd $LUNA_DEST_PATH/debian_pkgs
}

# The following method checks to see if the driver is in use.
# If so, abort uninstall.
verify_uninstallable_driver() 
{
    remove_driver $1
    if [ $? -ne 0 ] ; then
        echo "Aborting Luna Client uninstall...."
        echo "Luna $1 driver is in use."
        echo "Please stop the application using it or restart the machine."        
        exit 1
    fi
}

# The following methods are for stopping SafeNet services.
shutdown_services_linux()
{   
    service luna-snmp status > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        service luna-snmp stop
    fi
    service htlc_service status > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        service htlc_service stop 
    fi
    service pedclient_service status > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        service pedclient_service stop        
    fi
}

shutdown_services_solaris()
{
    SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/snmp/luna-snmp`
    if [ "$SERVICE" = "1" ]; then
        /etc/init.d/luna-snmp stop 
    fi
   SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/bin/pedClient`
    if [ "$SERVICE" = "1" ]; then
        /etc/init.d/pedclient_service stop 
    fi
    SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/htl/htl_client`
    if [ "$SERVICE" = "1" ]; then
        /etc/init.d/htlc_service stop 
    fi
}

shutdown_services_hpux()
{
    SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/snmp/luna-snmp`
    if [ "$SERVICE" = "1" ]; then
        /usr/local/bin/bash /sbin/init.d/luna-snmp stop 
    fi
    SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/bin/pedClient`
    if [ "$SERVICE" = "1" ]; then
        /usr/local/bin/bash /sbin/init.d/pedclient_service stop 
    fi
    SERVICE=`ps -ef | grep -v grep | grep -c $LUNA_DEST_PATH/htl/htl_client`
    if [ "$SERVICE" = "1" ]; then
        /usr/local/bin/bash /sbin/init.d/htlc_service stop 
    fi
}

shutdown_services_aix()
{
    PROCESS_ID=`ps -e -o pid,command | grep htl_client|awk '{print $1}'`
    if [ "$PROCESS_ID" != "" ]; then
        kill -9 $PROCESS_ID
    fi
}


#Starting point
# Change to the directory where the script is
FULL_PATH=`echo $0 | sed -e "s/\(.*\)\/.*/\1/"`
if [ "$FULL_PATH" != "$0" ] ; then
    cd $FULL_PATH
    echo "Installing from `pwd`"
    echo ""
fi

opt_uninstall=0
opt_uninstall_client=0
full_client_install=0
scriptable_install=0

#"Identify OS for which some products are not supported."
case `uname -s` in
    HP-UX)
        IS_OS_HP_UX=1               
    ;;
    AIX)
        IS_OS_AIX=1                 
    ;;      
esac


if [ "$1" = "help" ] || [ "$1" = "HELP" ] ; then
    display_install_help
    exit 0
fi

# Scriptable install section
if [ "$1" != "" ] ; then
    scriptable_install=1
    if [ "$1" = "remove_client" ] ; then
        # Uninstall case
        opt_uninstall=1
        opt_uninstall_client=1
    elif [ "$1" = "all" ] || [ "$1" = "ALL" ] ; then
        # Scriptable install to install all Luna products and components
        full_client_install=1
    else
        # Scriptable install with options provided
        # Get all products and components pased in
        scriptable_get_products_and_components "$*"

        if [ "$products_list"  = "" ] && [ "$components_list" = "" ] ; then
            echo "Installation error: Wrong options were given."
            display_install_help
            exit 1
        fi

        for product in $products_list
        do
            case "$product" in
                sa|SA)
                    LUNA_SA_SELECTED="*"
                ;;
    
                pci|PCI)
                    LUNA_PCI_SELECTED="*"
                ;;
    
                g5|G5)
                    LUNA_G5_SELECTED="*"
                ;;
    
                rb|RB)
                    LUNA_REM_BACKUP_HSM_SELECTED="*"
                ;;
    
                *)
                    echo "ERROR: Invalid product (-p) option."
                    display_install_help
                    exit 1
                ;;
            esac
        done

        LUNA_SDK_SELECTED=" "
        LUNA_JSP_SELECTED=" "
        LUNA_JCPROV_SELECTED=" "
        LUNA_DPC_SELECTED=" "
        LUNA_SNMP_SELECTED=" "

		if [ $IS_OS_AIX -eq 1 ]; then
			LUNA_PCI_SELECTED=""
			LUNA_G5_SELECTED=""
			LUNA_REM_BACKUP_HSM_SELECTED=""
		fi 

		if [ $IS_OS_HP_UX -eq 1 ]; then
			LUNA_G5_SELECTED=""
			LUNA_REM_BACKUP_HSM_SELECTED=""
		fi 
		
        # If no components are passed in only the default components are installed
        if [ "$components_list" = "" ] ; then
            if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_SA_SELECTED" = "*" ] ; then
                LUNA_SDK_SELECTED=" "
                LUNA_JSP_SELECTED="*"
                LUNA_JCPROV_SELECTED="*"
                if [ "$LUNA_SA_SELECTED" = "*" ] ; then
                    LUNA_DPC_SELECTED="*"
                fi
            fi
        elif [ "$components_list" = "all" ] ; then
            LUNA_SDK_SELECTED="*"
            LUNA_JSP_SELECTED="*"
            LUNA_JCPROV_SELECTED="*"
            if [ "$LUNA_SA_SELECTED" = "*" ] ; then
                LUNA_DPC_SELECTED="*"
            elif [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
                LUNA_SNMP_SELECTED="*"
            fi
        else

            # Get components list if any was passed in
            for component in $components_list
            do
                case "$component" in
                    sdk|SDK)
                        if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_SA_SELECTED" = "*" ] ; then
                            LUNA_SDK_SELECTED="*"
                        else
                            echo "ERROR: The specified component is not supported under the selected product."
                            echo "Please try another option or no (-c) option."
                            echo "Please note that Luna Remote Backup HSM (rb) only support Luna SNMP subagent product (snmp)."
                            display_install_help
                            exit 1
                        fi
                    ;;
    
                    jsp|JSP)
                        if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_SA_SELECTED" = "*" ] ; then
                            LUNA_JSP_SELECTED="*"
                        else
                            echo "ERROR: The specified component is not supported under the selected product."
                            echo "Please try another option or no (-c) option."
                            echo "Please note that Luna Remote Backup HSM (rb) only support Luna SNMP subagent product (snmp)."
                            display_install_help
                            exit 1
                        fi
                    ;;
    
                    jcprov|JCPROV)
                        if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_SA_SELECTED" = "*" ] ; then
                            LUNA_JCPROV_SELECTED="*"
                        else
                            echo "ERROR: The specified component is not supported under the selected product."
                            echo "Please try another option or no (-c) option."
                            echo "Please note that Luna Remote Backup HSM (rb) only support Luna SNMP subagent product (snmp)."
                            display_install_help
                            exit 1
                        fi
                    ;;
    
                    ldpc|LDPC)
                        if  [ "$LUNA_SA_SELECTED" = "*" ] ; then
                            LUNA_DPC_SELECTED="*"
                        else
                            echo "ERROR: The specified component is not supported under the selected product."
                            echo "Please try another option or no (-c) option."
                            echo "Please note that Luna Remote Backup HSM (rb) only support Luna SNMP subagent product (snmp)."
                            display_install_help
                            exit 1
                        fi
                    ;;
    
                    snmp|SNMP)
                        if [ "$LUNA_PCI_SELECTED" = "*" ] || [ "$LUNA_G5_SELECTED" = "*" ] || [ "$LUNA_REM_BACKUP_HSM_SELECTED" = "*" ] ; then
                            LUNA_SNMP_SELECTED="*"
                        else
                            echo "ERROR: The specified component is not supported under the selected product."
                            echo "Please try another option or no (-c) option."
                            echo "Please note that Luna SNMP subagent product (snmp) is not supported under Luna SA product (sa)."
                            display_install_help
                            exit 1
                        fi
                    ;;
    
                    *)
                        echo "ERROR: Invalid component (-c) option."
                        display_install_help
                        exit 1
                    ;;
                esac
            done
        fi
    fi

    get_os_info $opt_uninstall

    if [ $opt_uninstall -ne 1 ] ; then

        # Display License
        #display_license

        if [ $full_client_install -eq 1 ] ; then
            confirm_install
            all_client_pkgs="${CONFIG_PKG} ${CRYPTOKI_PKG} ${VKD_PKG} ${UHD_PKG} ${SHIM_PKG} ${VTL_PKG} ${CMU_PKG} ${CKDEMO_PKG} ${MULTITOKEN_PKG} ${SALOGIN_PKG} ${CKLOG_PKG} ${DIAG_PKG} ${CM_PKG} ${PEDCLIENT_PKG} ${RBS_PKG} ${HTLC_PKG} ${PTA_PKG} ${LUNA_SNMP_PKG} ${JCPROV_PKG} ${LUNADPC_PKG} ${JAVASAMP_PKG} ${CKSAMPLE_PKG} ${JCPROVSAMP_PKG} ${LUNAJSP_PKG} ${LUNAJMT_PKG}"
            client_pkgs=$all_client_pkgs
        else
            set_packages
        fi

        check_random
        save_conf_file

        # Install Luna Client packages now
        install_client "$client_pkgs"

    fi
fi

# Install using menu selections section
if [ $scriptable_install -eq 0 ] && [ $opt_uninstall -ne 1 ] ; then
    option=""
    get_os_info $opt_uninstall
    # Display License
    #display_license

    select_luna_products_and_components
    while [ "$option" = "b" ] || [ "$option" = "B" ]
    do
        select_luna_products_and_components
    done;

    # Set the packages list to be installed based on user selections
    set_packages
    
    # Show what is going to be installed
    echo
    echo "List of Luna Products to be installed:"
    if [ "$sa_client_pkgs" != "" ] ; then
        echo "- Luna SA"
    fi
    if [ "$pci_client_pkgs" != "" ] ; then
        echo "- Luna PCI-E"
    fi
    if [ "$g5_client_pkgs" != "" ] ; then
        echo "- Luna G5"
    fi
    if [ "$rb_client_pkgs" != "" ] ; then
        echo "- Luna Remote Backup HSM"
    fi
    
    echo
    echo "List of Luna Components to be installed:"
    if [ "$sdk_pkgs" != "" ] ; then
        echo "- Luna SDK"
    fi
    if [ "$jsp_pkgs" != "" ] ; then
        echo "- Luna JSP (Java)"
    fi
    if [ "$jcprov_client_pkgs" != "" ] ; then
        echo "- Luna JCProv (Java)"
    fi
    if [ "$ldpc_client_pkgs" != "" ] ; then
        echo "- Crypto Command Center Provisioning Client"
    fi
    if [ "$snmp_client_pkgs" != "" ] ; then
        echo "- Luna SNMP subagent"
    fi
    echo

    # Check Random
    check_random

    # Save config file
    save_conf_file

    # Install Luna Client packages now
    install_client "$client_pkgs"
    # echo "Installation of the Luna Client ${VERSION}-${RELEASE} completed."

fi

if [ $opt_uninstall_client -eq 1 ] ; then
    # Confirm uninstall
    if [ "$2" != "" ] ; then
        # confirm uninstall
        echo ""
        echo "Are you sure you want to uninstall the Luna Client ${VERSION}-${RELEASE} features"
        prompt_yes_no "specified? (y/n) "
        if [ $? -eq 1 ] ; then
            exit 1
        fi
    fi
    
    # shutdown all SafeNet services
    shutdown_services_$OSNAME
    
    # verify drivers can be uninstalled
    if [ "$OSNAME" = "hpux" ] || [  "$VKD_PKG" != "" ] ; then
        DRIVER_NAME="vkd"
        verify_uninstallable_driver $DRIVER_NAME
    elif [  "$VKD_PKG" != "" ] ; then
        verify_uninstallable_driver $VKD_PKG     
    fi
    
    if [  "$UHD_PKG" != "" ] ; then
        verify_uninstallable_driver $UHD_PKG
    fi
    
    # We are going to perform the uninstall.
    # Uninstall client
    if [ "$client_uninstall_pkgs" != "" ] ; then
        uninstall_client "$client_uninstall_pkgs"
    fi

fi

if [ $opt_uninstall_client -ne 0 ] ; then
    # Remove scripts if there is no package installed
    is_any_pkg_installed

    if [ $? -ne 0 ] ; then
       rm -f $LUNA_DEST_PATH/bin/common 2>/dev/null
       rm -f $LUNA_DEST_PATH/bin/uninstall.sh 2>/dev/null
    fi
fi
