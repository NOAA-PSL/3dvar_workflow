# need envars:  analdate, datapath, s3path

which aws
if [ $? -ne 0 ]; then
   echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME machine=${machine}"
   if  [ $SLURM_CLUSTER_NAME == 'es' ]; then #
      if [ $machine == "gaeac5" ]; then
         module use /ncrc/proj/epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      elif [ $machine == "gaeac6" ]; then
         module use /ncrc/proj/epic/spack-stack/c6/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      fi
      module load stack-intel
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hercules' ]; then
      module purge
      module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core 
      module load stack-intel/2021.9.0
      module load awscli-v2
   else
      echo "cluster must be 'hercules' or 'es' (gaea)"
      exit 1
   fi
fi
which aws
if [ $? -ne 0 ]; then
   echo "awscli not found"
   exit 1
fi
if [ ! -s ~/.aws/credentials  ]; then
   echo "no aws credentials"
   exit 1
fi

cd $datapath
MM=`echo $analdate | cut -c5-6`
YYYY=`echo $analdate | cut -c1-4`
s3path=s3://noaa-reanalyses-pds/analyses/scout_runs/GSI3DVar/1997stream_new/${YYYY}/${MM}/${analdate}/
aws s3 cp --recursive --only-show-errors ${analdate} $s3path --profile aws-nnja

if [ $? -ne 0 ]; then
  echo "s3 archive failed "$filename
  exitstat=1
else
  echo "s3 archive succceeded "$filename
  echo "data written to ${s3path}"
  aws s3 ls --no-sign-request $s3path
  # remove everything except logs, gsistats and  abias* files
  /bin/rm -f ${analdatem1}/*diag*nc* ${analdate}/sfg* ${analdate}/bfg* ${analdate}/sanl* ${analdate}/gsiparm.anl
  /bin/rm -rf ${analdate}/control
fi
exit $exitstat
