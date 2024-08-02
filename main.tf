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
variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."

  validation {
    condition = length(var.agent_id) > 0
    error_message = "The agent ID must be provided."
  }
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
  default = "{}"
}

variable "vscode_extensions" {
  type        = list(string)
  description = "VS Code extensions to install."
  default     = []
}

variable "coder_init_script" {
  type        = string
  description = "The Coder init script."
  
  validation {
    condition = length(var.coder_init_script) > 0
    error_message = "The Coder init script must be provided."
  }
}



resource "coder_script" "install-dependencies" {
  agent_id = var.agent_id
  display_name = "Install dependencies"
  script   = templatefile("${path.module}/scripts/install-dependencies.sh", {})
  run_on_start = true
  start_blocks_login = true
}


resource "coder_script" "install-vscode" {
  agent_id = var.agent_id
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
    # dockerfile = "${path.module}/docker/Dockerfile"

    no_cache = true
    build_args = {
      USER = var.username
      SSHD_PORT = var.sshd_port
      CODER_INIT_SCRIPT = var.coder_init_script
      SETUP_ENV_SCRIPT = var.setup_env_script
      WORKSPACE_FILE = var.workspace_file
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.module}/docker", "**") : filesha1("${path.module}/docker/${f}")]))
  }
}

output "docker_image_name" {
  value = docker_image.main.name
  
}