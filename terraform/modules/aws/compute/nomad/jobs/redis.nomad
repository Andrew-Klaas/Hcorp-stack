# There can only be a single job definition per file.
# Create a job with ID and Name 'example'
job "redis" {
	datacenters = ["dc1"]

	type = "service"

 	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	update {
		stagger = "10s"
		max_parallel = 1
	}
	group "cache" {
		count = 3
		restart {
			attempts = 10
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}
		task "redis" {
			driver = "docker"
			config {
				image = "redis:latest"
				port_map {
					db = 6379
				}
			}
			service {
				name = "${TASKGROUP}-redis"
				tags = ["urlprefix-redis/"]
				port = "db"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			# We must specify the resources required for
			# this task to ensure it runs on a machine with
			# enough capacity.
			resources {
				cpu = 500 # 500 MHz
				memory = 256 # 256MB
				network {
					mbits = 10
					port "db" {
					}
				}
			}

			# The artifact block can be specified one or more times to download
			# artifacts prior to the task being started. This is convenient for
			# shipping configs or data needed by the task.
			# artifact {
			#	  source = "http://foo.com/artifact.tar.gz"
			#	  options {
			#	      checksum = "md5:c4aa853ad2215426eb7d70a21922e794"
			#     }
			# }
			
			# Specify configuration related to log rotation
			# logs {
			#     max_files = 10
			#     max_file_size = 15
			# }
			 
			# Controls the timeout between signalling a task it will be killed
			# and killing the task. If not set a default is used.
			# kill_timeout = "20s"
		}
	}
}
