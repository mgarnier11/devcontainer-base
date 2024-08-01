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
variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
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
}

# variable "setup_script" {
#   type        = string
#   description = "A script to run on workspace setup."
# }

variable "vscode_extensions" {
  type        = list(string)
  description = "VS Code extensions to install."
}

variable "coder_init_script" {
  type        = string
  description = "The Coder init script."
  
}

# Output variables

output "docker_image_name" {
  value = "${docker_image.main.name}"
  
}



resource "coder_script" "install" {
  agent_id = var.agent_id
  display_name = "Install requirements"
  script   = templatefile("${path.module}/scripts/install.sh", {})
  run_on_start = true
  start_blocks_login = true
}


resource "coder_script" "install-vscode" {
  agent_id = var.agent_id
  display_name = "Install requirements"
  script   = templatefile("${path.module}/scripts/install-vscode-web.sh", {
    PORT : var.vscode_web_port,
    LOG_PATH : "/tmp/vscode-web.log",
    INSTALL_PREFIX : "/tmp/vscode-web",
    EXTENSIONS : join(",", var.vscode_extensions),
    TELEMETRY_LEVEL : "off",
    # SETTINGS : replace(jsonencode(var.settings), "\"", "\\\""),
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
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./docker"
    no_cache = true
    build_args = {
      USER = var.username
      SSHD_PORT = var.sshd_port
      CODER_INIT_SCRIPT = var.coder_init_script
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "docker/**") : filesha1(f)]))
  }
}