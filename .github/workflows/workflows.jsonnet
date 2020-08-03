local lm = import "github.com/cakehappens/lonely-mountain/main.libsonnet";

{
  checkout_:: {
    uses: "actions/checkout@v2",
  },

  ".github/workflows/main": {
    local workflow = self,

    name: "main",
    on: {
      push: {
        branches: [
          "main",
        ],
        "paths-ignore": [
          'docs/**',
          'scripts/**',
          'jsonnetfile.*',
          'Makefile',
          'README.md',
          '.github/workflows/**',
          '!.github/workflows/main.yml',
        ],
      },
      // pull_request: {
      //   branches: [
      //     "main",
      //   ],
      //   "paths-ignore": lm.obj.valuesPruned($.paths_ignore_),
      // },
    },
    jobs: {
      hadolint: {
        name_:: "hadolint",
        "runs-on": "ubuntu-latest",
        steps: [
          $.checkout_,
          {
            uses: "brpaz/hadolint-action@master",
          },
        ],
      },
      build_and_push: {
        name_:: "build_and_push",
        name: "docker build and push",
        "runs-on": "ubuntu-latest",
        needs: [ workflow.jobs.hadolint.name_ ],
        steps: [
          $.checkout_,
          // {
          //   uses: "kciter/aws-ecr-action@v1",
          //   with: {
          //     access_key_id: "${{ secrets.AWS_ACCESS_KEY_ID }}",
          //     secret_access_key: "${{ secrets.AWS_SECRET_ACCESS_KEY }}",
          //     account_id: "${{ secrets.AWS_ACCOUNT_ID }}",
          //     repo: "cakehappens/realworld-kubernetes-gitops",
          //     region: "us-west-2",
          //     tags: "${{ github.sha }}",
          //     create_repo: false,
          //   },
          // },
          {
            uses: "docker/build-push-action@v1",
            with: {
              username: "${{ secrets.DOCKER_USERNAME }}",
              password: "${{ secrets.DOCKER_PASSWORD }}",
              repository: "cakehappens/realworld-kubernetes-gitops",
              tags: "${{ github.sha }}",
            },
          },
        ],
      },
      render_manifests: {
        name_:: "render_manifests",
        name: "render manifests",
        "runs-on": "ubuntu-latest",
        steps: [
          $.checkout_,
          {
            uses: "./.github/actions/jsonnet",
            with: {
              args: "jsonnet --help"
            },
          },
        ],
      },
      deploy: {
        name_:: "deploy",
        name: "deploy",
        "runs-on": "ubuntu-latest",
        needs: [ workflow.jobs.render_manifests ],
        steps: [
          {
            uses: "steebchen/kubectl@master",
            env: {
              KUBECTL_VERSION: "1.14",
              KUBE_CONFIG_DATA: "${{ secrets.KUBE_CONFIG_DATA }}",
            },
            with: {
              args: "version"
            },
          },
        ],
      },
    },
  },
  // ".github/workflows/dockerhub-description": {
  //   name: "Update Docker Hub Description",
  //   on: {
  //     push: {
  //       branches: [
  //         "main",
  //       ],
  //       paths: [
  //         "docs/docker.md",
  //         ".github/workflows/dockerhub-description.yml",
  //       ],
  //     },
  //   },
  //   jobs: {
  //     dockerHubDescription: {
  //       "runs-on": "ubuntu-latest",
  //       steps: [
  //         $.checkout_,
  //         {
  //           uses: "peter-evans/dockerhub-description@v2",
  //           env: {
  //             DOCKERHUB_USERNAME: "${{ secrets.DOCKER_USERNAME }}",
  //             DOCKERHUB_PASSWORD: "${{ secrets.DOCKER_PASSWORD }}",
  //             DOCKERHUB_REPOSITORY: "cakehappens/realworld-kubernetes-gitops",
  //             README_FILEPATH: "./docs/docker.md",
  //           },
  //         },
  //       ],
  //     },
  //   },
  // },
}
