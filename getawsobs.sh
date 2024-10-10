obtyp_default="all"
YYYYMMDDHH=${analdate:-$1}
OUTPATH=${obs_datapath:-$2}
obtyp=${obtyp_default:-$3} # specify single ob type, default is all obs.
nbackmax=${nbackmax:-10}

which aws
if [ $? -ne 0 ]; then
   echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME"
   if  [ $SLURM_CLUSTER_NAME == 'es' ]; then #
      module use /ncrc/proj/epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      module load stack-intel/2023.1.0
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hercules' ]; then
      module purge
      module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core 
      module load stack-intel/2021.9.0
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hera' ]; then
      module purge
      module use /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.6.0/envs/unified-env-rocky8/install/modulefiles/Core 
      module load stack-intel/2021.5.0
      module load awscli-v2
   else
      echo "cluster must be 'hera', 'hercules' or 'es' (gaea)"
      exit 1
   fi
fi
which aws
if [ $? -ne 0 ]; then
   echo "awscli not found"
   exit 1
fi

AWS_ACCESS_KEY_ID=''
AWS_SECRET_ACCESS_KEY=''

YYYYMM=`echo $YYYYMMDDHH | cut -c1-6`
YYYYMMDD=`echo $YYYYMMDDHH | cut -c1-8`
HH=`echo $YYYYMMDDHH | cut -c9-10`
DD=`echo $YYYYMMDDHH | cut -c7-8`
MM=`echo $YYYYMMDDHH | cut -c5-6`
YYYY=`echo $YYYYMMDDHH | cut -c1-4`
CDUMP='gdas'
S3PATH=/noaa-reanalyses-pds/observations/reanalysis
S3PATH_PRIVATE=/nnja-private-eumetsat/observations/reanalysis
# directory structure required by global-workflow
TARGET_DIR=${OUTPATH}/${CDUMP}.${YYYYMMDD}/${HH}/atmos
mkdir -p $TARGET_DIR
#obtypes=("airs" "airs" "amsua" "amsub" "amv" "atms" "cris" "cris" "geo" "geo" "gps" "hirs" "hirs" "hirs" "iasi" "mhs" "msu" "saphir" "seviri" "ssmi" "ssmis" "ssu")
obtypes=("airs" "amsua" "amsua" "amsub""atms" "cris" "cris" "geo" "geo" "hirs" "hirs" "hirs" "iasi" "mhs" "msu" "saphir" "seviri" "ssu")
#if [ $YYYYMMDDHH -lt "0009050106" ]; then
## before 2009050106 for amsua use nasa/r21c_repro/gmao_r21c_repro
#   dirs=("nasa" "nasa/r21c_repro" "1bamub" "merged" "atms" "cris" "crisf4" "goesnd" "goesfv" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "eumetsat" "eumetsat" "1bssu")
#   obnames=("aqua" "1bamu" "1bamub" "satwnd" "atms" "cris" "crisf4" "goesnd" "goesfv" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "ssmit" "ssmisu" "1bssu")
#   dumpnames=("airs_disc_final" "gmao_r21c_repro" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
if [ $YYYYMMDDHH -ge "2001090106" ] &&  [ $YYYYMMDDHH -le "2016123118" ]; then
   # use EUMETSAT reprocessed gpsro
   #dirs=("nasa" "airsev" "1bamua" "1bamub" "merged" "atms" "cris" "crisf4" "goesnd" "goesfv" "eumetsat" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "eumetsat" "eumetsat" "1bssu")
   #obnames=("aqua" "airsev" "1bamua" "1bamub" "satwnd" "atms" "cris" "crisf4" "goesnd" "goesfv" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "ssmit" "ssmisu" "1bssu")
   #dumpnames=("airs_disc_final" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
   dirs=("nasa" "nasa" "1bamua" "1bamub" "atms" "cris" "crisf4" "goesnd" "goesfv" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "1bssu")
   obnames=("aqua" "aqua" "1bamua" "1bamub" "atms" "cris" "crisf4" "goesnd" "goesfv" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "1bssu")
   dumpnames=("airs_disc_final" "amsua_disc_final" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
else
   #dirs=("nasa" "airsev" "1bamua" "1bamub" "merged" "atms" "cris" "crisf4" "goesnd" "goesfv" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "eumetsat" "eumetsat" "1bssu")
   #obnames=("aqua" "airsev" "1bamua" "1bamub" "satwnd" "atms" "cris" "crisf4" "goesnd" "goesfv" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "ssmit" "ssmisu" "1bssu")
   #dumpnames=("airs_disc_final" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
   dirs=("nasa" "nasa" "1bamua" "1bamub" "atms" "cris" "crisf4" "goesnd" "goesfv" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "1bssu")
   obnames=("aqua" "aqua" "1bamua" "1bamub" "atms" "cris" "crisf4" "goesnd" "goesfv" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "1bssu")
   dumpnames=("airs_disc_final" "amsua_disc_final" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
fi
nback=0
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     if [ ${obtypes[$n]} == "airs" ] && [ ${dirs[$n]} == "nasa" ]; then
        # NASA airs obs
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.airsev.tm00.bufr_d"
     #elif [ ${obtypes[$n]} == "airs" ] && [ ${dirs[$n]} == "airsev" ]; then
     #   # obtype=airs obname=airsev dir=airsev dumpname=gdas
     #   # amsua data from NCEP airsev file
     #   s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     #   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.aquaamua.tm00.bufr_d"
     elif [ ${obtypes[$n]} == "amsua" ] && [ ${dirs[$n]} == "nasa" ]; then
        # obtype=amsua obname=aqua dir=nasa dumpname=amsua_disc_final
        # NASA airs obs
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.aquaamua.tm00.bufr_d"
     elif [ ${obtypes[$n]} == "amsua" ] && [ ${dirs[$n]} == "nasa/r21c_repro" ]; then
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.1bamua.tm00.bufr_d"
     else
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     fi
     #aws s3 ls --no-sign-request $s3file
     nback=$[$nback+1]
     aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
     if [ $nback -eq $nbackmax ]; then
        wait
	nback=0
     fi
     #ls -l $localfile
  fi
done
wait
# prepbufr
obtypes="prepbufr prepbufr.acft_profiles"
for obtype in $obtypes; do
   if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
      if [ $obtype == "prepbufr" ]; then
         s3file=s3:/"${S3PATH}/conv/${obtype}/${YYYY}/${MM}/prepbufr/gdas.${YYYYMMDD}.t${HH}z.${obtype}.nr"
      else
         s3file=s3:/"${S3PATH}/conv/${obtype}/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.${obtype}.nr"
      fi
      localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obtype}"
      #aws s3 ls --no-sign-request $s3file
      aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
      #ls -l $localfile
   fi
done
# ozone
# CFSR
if [ $obtyp == "osbuv8" ] || [ $obtyp == "all" ]; then
   s3file=s3:/"${S3PATH}/ozone/cfsr/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.osbuv8.tm00.bufr_d"
   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.osbuv8.tm00.bufr_d"
   #aws s3 ls --no-sign-request $s3file
   aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
   #ls -l $localfile
fi
# NCEP bufr
obtypes=("ozone" "ozone" "ozone")
dirs=("ncep" "ncep" "ncep")
obnames=("ompslp" "ompsn8" "ompst8")
dumpnames=("gdas" "gdas" "gdas")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     #aws s3 ls --no-sign-request $s3file
     aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
     #ls -l $localfile
  fi
done
# NASA bufr
if [ $obtyp == "sbuv_v87" ] || [ $obtyp == "all" ]; then
   s3file=s3:/"${S3PATH}/ozone/nasa/sbuv_v87/${YYYY}/${MM}/bufr/sbuv_v87.${YYYYMMDD}.${HH}z.bufr"
   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.sbuv_v87.tm00.bufr_d"
   #aws s3 ls --no-sign-request $s3file
   aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
   #ls -l $localfile
fi
# NASA netcdf
obtypes=("ozone" "ozone" "ozone" "ozone" "ozone")
dirs=("nasa" "nasa" "nasa" "nasa" "nasa")
obnames=("mls" "omi-eff" "omps-lp" "omps-nm-eff" "omps-nm")
dumpnames=("MLS-v5.0-oz" "OMIeff-adj" "OMPS-LPoz-Vis" "OMPSNM" "OMPSNP")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/netcdf/${dumpnames[$n]}.${YYYYMMDD}_${HH}z.nc"
     localfile="${TARGET_DIR}/${dumpnames[$n]}.${YYYYMMDD}_${HH}z.nc"
     #aws s3 ls --no-sign-request $s3file
     aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
     #ls -l $localfile
  fi
done
wait
#prviate eumetsat data
obstypes=("gps" "ssmi" "amv" "ssmis")
dirs=("eumetsat" "eumetsat" "merged" "eumetsat")
obnames=("gpsro" "ssmit" "satwnd" "ssmisu")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     s3file=s3:/"${S3PATH_PRIVATE}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws s3 cp --only-show-errors $s3file $localfile &
  fi
done
wait
ls -l ${TARGET_DIR}
