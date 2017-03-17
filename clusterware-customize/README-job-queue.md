# Custom job validators and job runners for `alces customize job-queue`

## Default job running

By default a job added to a customizer queue will be treated as an executable
file and executed.  It will be called with two arguments:

 1. the role of the instance executing the job
 2. the cluster's name.

Currently customizer queue jobs for a cluster will be picked up from
`s3://${customizer_bucket}/customizer/${customizer_name}` (referred from here
in this document as `$customizer_profile`) when the Clusterware periodic
cronjob runs, where `$customizer_bucket` refers to the customizer bucket for
the account (e.g. `alces-flight-nmi0ztdmyzm3ztm3`), and `$customizer_name`
refers to any customizer profile name (e.g.  `prime-continuous-delivery` or
`domain-dev.alces.network`).

For each such customizer profile, a particular cluster with name
`$cluster_name` will process any scripts in
`$customizer_profile/job-queue.d/${cluster_name}/pending`. One way to add
scripts to a queue for a cluster is to manually upload them to the appropriate
folder; another way is to use the `alces customize job-queue put
$customizer_name $script`, which will upload the given `$script` to the
`$customizer_name` customizer profile queue for that cluster.

Note that currently jobs will only be run on the master node for a cluster.
However, multiple clusters with the same name in different domains for an
account will currently all pick up and process the same job, unless one cluster
completes processing it before another picks it up.

The results of running the job are stored on s3 with the following prefix:
`$customizer_profile/job-queue.d/${cluster_name}`. Specifically, output will
be available at `${prefix}/completed/${job_id}/logs` and its exit code will be
available at `${prefix}/completed/${job_id}/status.`

## Custom job runners

It is possible to customize a job queue with an alternate job running strategy.
To do so create the file: `$customizer_profile/share/process-job`.

When a node executes a job, instead of executing the job script directly, it
will execute the `process-job` script.  The `process-job` script will be called
with 4 arguments:

 1. the path to the job script to run
 2. a directory path into which additional output files can be written
 3. the role of the instance executing the job
 4. the cluster's name.

Possible uses of custom job runners include: creating additional output files,
interpreting the job script in some non-standard manner, running the job script
in a non-standard location.

An example job runner which creates some additional output files and runs the
job file in the standard manner is shown below.

```bash
main () {
  local job_file output_dir instance_role cluster_name exit_code
  job_file="$1"
  output_dir="$2"
  instance_role="$3"
  cluster_name="$4"

  mkdir -p "${output_dir}"
  date > "${output_dir}"/started_at
  chmod +x "${job_file}"
  "${job_file}" "${instance_role}" "${cluster_name}"
  exit_code=$?
  date > "${output_dir}"/completed_at
  return $exit_code
}

main "$@"
```

Our next example of a custom job runner will interpret a job script containing
key value pairs.  An example of the kind of job script it will interpret is:

```
operation=install
package=ffmpeg
```

For this job script, the job runner should use a package manager to install the
package `ffmpeg`.  The following is a simple custom job runner which would do
just that.

```bash
main () {
  local job_file
  job_file="$1"

  operation=$(grep ^operation= "${job_file}" | cut -f2 -d=)
  package=$(grep ^package= "${job_file}" | cut -f2 -d=)

  package-manager "${operation}" "${package}"
}

main "$@"
```

The same custom job runner is used for all clusters using that queue.


## Custom job validators

When writing a custom job runner to interpret job scripts in some non-standard
way, one may wish to validate ensure that the job script is valid before
running it.  This can be done by writing a custom job validator for the job
queue customizer.

The custom job validator resides at `$customizer_profile/share/validate-job`.
It will be called with two arguments:

 1. the path to the job file to validate,
 2. a directory path into which additional output files can be written.

If the job file is valid, validate-job should exit with a 0 exit code.  Any
other exit code indicates that the job file is invalid.  If the job file is
invalid, any output written to standard output by the validate-job script will
be saved to s3.

An example custom job validator, which is designed to work with the custom job
runner developed earlier is given below.

```bash
main () {
  local job_file
  job_file="$1"

  grep -qL ^operation= "${job_file}" 
  if [ $? -ne 0 ] ; then
      echo "Missing operation key"
      exit 1
  fi
  grep -qL ^package= "${job_file}" 
  if [ $? -ne 0 ] ; then
      echo "Missing package key"
      exit 1
  fi

  return 0
}

main "$@"
```
