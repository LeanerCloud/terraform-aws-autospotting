# terraform-aws-autospotting
Automatically convert your existing AutoScaling groups to significantly cheaper spot instances with minimal(often zero) configuration changes


See [https://github.com/autospotting/autospotting](https://github.com/autospotting/autospotting) for details.

To access from terraform:

```
module "autospotting" {
  source  = "cristim/autospotting/aws"
  version = "0.0.9"
}
```
