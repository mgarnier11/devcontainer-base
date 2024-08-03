# Terraform declarations
terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.17"
    }

    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# Input variables
variable "image_name" {
  type        = string
  description = "The name of the Docker image to build."
  default     = "coder-devcontainer"
}

variable arch {
  type = string
  description = "The architecture of the agent."
}

variable os {
  type = string
  description = "The operating system of the agent."
}

variable "sshd_port" {
  type        = number
  description = "The port to the SSH server on."
  default     = 13338
}

variable "vscode_web_port" {
  type        = number
  description = "The port to run VS Code Web on."
  default     = 13339
}

variable "username" {
  type        = string
  description = "The username of the workspace user."
  default     = "coder"
}

variable "setup_env_script" {
  type        = string
  description = "A script to run after workspace setup."
  default = "echo 'No setup env script provided.'"
}

variable "workspace_file" {
  type        = string
  description = "The vscode workspace file to use."
  default = ""
}

variable "workspace_file_json" {
  type        = any
  description = "The json vscode workspace file to use."
  default = ""
}

variable "vscode_extensions" {
  type        = list(string)
  description = "VS Code extensions to install."
  default     = []
}

variable "install_coder" {
  type        = bool
  description = "Install coder CLI in the workspace."
  default     = false
}

variable "install_tasks" {
  type        = bool
  description = "Install task in the workspace."
  default     = false
}

variable "install_go" {
  type        = bool
  description = "Install Go in the workspace."
  default     = false
}

variable "install_nvm" {
  type        = bool
  description = "Install NVM in the workspace."
  default     = false  
}

resource "coder_agent" "main" {
  arch            = var.arch
  os              = var.os
  
  display_apps {
    vscode = false
    port_forwarding_helper = false
    ssh_helper = false
  }


  metadata {
    display_name = "CPU Usage"
    key          = "container_cpu_usage"
    script       = "coder stat cpu"
    interval     = 20
    timeout      = 1
    order        = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "contaier_ram_usage"
    script       = "coder stat mem"
    interval     = 20
    timeout      = 1
    order        = 2
  }

  
  metadata {
    display_name = "CPU Usage (Host)"
    key          = "host_cpu_usage"
    script       = "coder stat cpu --host"
    interval     = 20
    timeout      = 1
    order        = 3
  }

  metadata {
    display_name = "RAM Usage (Host)"
    key          = "host_ram_usage"
    script       = "coder stat mem --host"
    interval     = 20
    timeout      = 1
    order        = 4
  }

    metadata {
    display_name = "Storage"
    key          = "storage"
    script       = "coder stat disk"
    interval     = 60
    timeout      = 1
    order        = 5
  }
}

resource "coder_script" "install-dependencies" {
  agent_id = coder_agent.main.id
  display_name = "Install dependencies"
  script   = templatefile("${path.module}/scripts/install-dependencies.sh", {
    INSTALL_CODER : var.install_coder,
    INSTALL_TASKS : var.install_tasks,
    INSTALL_GO : var.install_go,
    INSTALL_NVM : var.install_nvm,
  })
  run_on_start = true
  start_blocks_login = true
}


resource "coder_script" "install-vscode" {
  agent_id = coder_agent.main.id
  display_name = "Install vscode-web"
  script   = templatefile("${path.module}/scripts/install-vscode-web.sh", {
    PORT : var.vscode_web_port,
    LOG_PATH : "/tmp/vscode-web.log",
    INSTALL_PREFIX : "/tmp/vscode-web",
    EXTENSIONS : join(",", var.vscode_extensions),
    TELEMETRY_LEVEL : "off",
    OFFLINE : false,
    USE_CACHED : false,
    EXTENSIONS_DIR : "/home/${var.username}/.vscode-server/extensions",
    FOLDER : "/home/${var.username}",
    AUTO_INSTALL_EXTENSIONS : true,


  })
  run_on_start = true
  start_blocks_login = true
}

resource "docker_image" "main" {
  name = var.image_name
  build {
    context = "${path.module}/docker"

    no_cache = true
    build_args = {
      USER = var.username
      SSHD_PORT = var.sshd_port
      CODER_INIT_SCRIPT = replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
      SETUP_ENV_SCRIPT = var.setup_env_script
      WORKSPACE_FILE = var.workspace_file != "" ? var.workspace_file : jsonencode(var.workspace_file_json)
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.module}/docker", "**") : filesha1("${path.module}/docker/${f}")]))
  }
}

output "docker_image_name" {
  value = docker_image.main.name
}

output "agent_id" {
  value = coder_agent.main.id
}

output "agent_token" {
  value = coder_agent.main.token
}