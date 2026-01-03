[1mdiff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml[m
[1mindex c2ac1ac..8d3580e 100644[m
[1m--- a/.github/workflows/ci.yml[m
[1m+++ b/.github/workflows/ci.yml[m
[36m@@ -6,6 +6,10 @@[m [mon:[m
   pull_request:[m
     branches: [ main ][m
 [m
[32m+[m[32menv:[m
[32m+[m[32m  REGISTRY: ghcr.io[m
[32m+[m[32m  IMAGE_NAME: ${{ github.repository }}[m
[32m+[m
 jobs:[m
   test:[m
     runs-on: ubuntu-latest[m
[36m@@ -53,9 +57,13 @@[m [mjobs:[m
         flags: unittests[m
         fail_ci_if_error: false[m
 [m
[31m-  docker-build:[m
[32m+[m[32m  build-and-push:[m
     runs-on: ubuntu-latest[m
     needs: test[m
[32m+[m[32m    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/'))[m
[32m+[m[32m    permissions:[m
[32m+[m[32m      contents: read[m
[32m+[m[32m      packages: write[m
 [m
     steps:[m
     - uses: actions/checkout@v3[m
[36m@@ -63,32 +71,31 @@[m [mjobs:[m
     - name: Set up Docker Buildx[m
       uses: docker/setup-buildx-action@v2[m
 [m
[31m-    - name: Log in to Docker Hub[m
[31m-      if: github.event_name != 'pull_request'[m
[32m+[m[32m    - name: Log in to GitHub Container Registry[m
       uses: docker/login-action@v2[m
       with:[m
[31m-        username: ${{ secrets.DOCKER_USERNAME }}[m
[31m-        password: ${{ secrets.DOCKER_TOKEN }}[m
[32m+[m[32m        registry: ${{ env.REGISTRY }}[m
[32m+[m[32m        username: ${{ github.actor }}[m
[32m+[m[32m        password: ${{ secrets.GITHUB_TOKEN }}[m
 [m
     - name: Extract metadata[m
       id: meta[m
       uses: docker/metadata-action@v4[m
       with:[m
[31m-        images: |[m
[31m-          ${{ secrets.DOCKER_USERNAME }}/php-hello-world[m
[32m+[m[32m        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}[m
         tags: |[m
           type=ref,event=branch[m
[31m-          type=ref,event=pr[m
           type=semver,pattern={{version}}[m
           type=semver,pattern={{major}}.{{minor}}[m
[31m-          type=sha[m
[32m+[m[32m          type=sha,prefix={{branch}}-[m
[32m+[m[32m          type=raw,value=latest,enable={{is_default_branch}}[m
 [m
     - name: Build and push Docker image[m
       uses: docker/build-push-action@v4[m
       with:[m
         context: .[m
         platforms: linux/amd64,linux/arm64[m
[31m-        push: ${{ github.event_name != 'pull_request' }}[m
[32m+[m[32m        push: true[m
         tags: ${{ steps.meta.outputs.tags }}[m
         labels: ${{ steps.meta.outputs.labels }}[m
         cache-from: type=gha[m
[36m@@ -113,4 +120,26 @@[m [mjobs:[m
       uses: github/codeql-action/upload-sarif@v2[m
       if: always()[m
       with:[m
[31m-        sarif_file: 'trivy-results.sarif'[m
\ No newline at end of file[m
[32m+[m[32m        sarif_file: 'trivy-results.sarif'[m
[32m+[m
[32m+[m[32m  scan-image:[m
[32m+[m[32m    runs-on: ubuntu-latest[m
[32m+[m[32m    needs: build-and-push[m
[32m+[m[32m    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/'))[m
[32m+[m[32m    permissions:[m
[32m+[m[32m      contents: read[m
[32m+[m[32m      packages: read[m
[32m+[m[32m      security-events: write[m
[32m+[m
[32m+[m[32m    steps:[m
[32m+[m[32m    - name: Run Trivy on Docker image[m
[32m+[m[32m      uses: aquasecurity/trivy-action@master[m
[32m+[m[32m      with:[m
[32m+[m[32m        image-ref: ${{ env.REGISTRY }}/${{ github.repository }}:${{ github.sha }}[m
[32m+[m[32m        format: 'sarif'[m
[32m+[m[32m        output: 'trivy-image-results.sarif'[m
[32m+[m
[32m+[m[32m    - name: Upload Trivy results to GitHub Security tab[m
[32m+[m[32m      uses: github/codeql-action/upload-sarif@v2[m
[32m+[m[32m      with:[m
[32m+[m[32m        sarif_file: 'trivy-image-results.sarif'[m
\ No newline at end of file[m
[1mdiff --git a/.github/workflows/deploy.yml b/.github/workflows/deploy.yml[m
[1mindex 3d07630..1b2c662 100644[m
[1m--- a/.github/workflows/deploy.yml[m
[1m+++ b/.github/workflows/deploy.yml[m
[36m@@ -1,25 +1,45 @@[m
 name: Deploy to Production[m
 [m
 on:[m
[31m-  push:[m
[31m-    tags:[m
[31m-      - 'v*'[m
   workflow_dispatch:[m
[32m+[m[32m    inputs:[m
[32m+[m[32m      tag:[m
[32m+[m[32m        description: 'Image tag to deploy (e.g., v1.0.0, main, sha-abc123)'[m
[32m+[m[32m        required: true[m
[32m+[m[32m        type: string[m
[32m+[m[32m  workflow_run:[m
[32m+[m[32m    workflows: ["CI Pipeline"][m
[32m+[m[32m    types:[m
[32m+[m[32m      - completed[m
[32m+[m[32m    branches:[m
[32m+[m[32m      - main[m
 [m
 env:[m
   REGISTRY: ghcr.io[m
   IMAGE_NAME: ${{ github.repository }}[m
 [m
 jobs:[m
[31m-  build-and-push:[m
[32m+[m[32m  deploy:[m
     runs-on: ubuntu-latest[m
[32m+[m[32m    if: |[m
[32m+[m[32m      github.event_name == 'workflow_dispatch' ||[m
[32m+[m[32m      (github.event.workflow_run.conclusion == 'success' && github.event.workflow_run.event == 'push')[m
     permissions:[m
       contents: read[m
[31m-      packages: write[m
[32m+[m[32m      packages: read[m
 [m
     steps:[m
     - uses: actions/checkout@v3[m
 [m
[32m+[m[32m    - name: Set deployment tag[m
[32m+[m[32m      id: set-tag[m
[32m+[m[32m      run: |[m
[32m+[m[32m        if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then[m
[32m+[m[32m          echo "tag=${{ github.event.inputs.tag }}" >> $GITHUB_OUTPUT[m
[32m+[m[32m        else[m
[32m+[m[32m          echo "tag=main-${{ github.event.workflow_run.head_sha }}" >> $GITHUB_OUTPUT[m
[32m+[m[32m        fi[m
[32m+[m
     - name: Log in to GitHub Container Registry[m
       uses: docker/login-action@v2[m
       with:[m
[36m@@ -27,31 +47,9 @@[m [mjobs:[m
         username: ${{ github.actor }}[m
         password: ${{ secrets.GITHUB_TOKEN }}[m
 [m
[31m-    - name: Extract metadata[m
[31m-      id: meta[m
[31m-      uses: docker/metadata-action@v4[m
[31m-      with:[m
[31m-        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}[m
[31m-        tags: |[m
[31m-          type=semver,pattern={{version}}[m
[31m-          type=semver,pattern={{major}}.{{minor}}[m
[31m-          type=raw,value=latest,enable={{is_default_branch}}[m
[31m-[m
[31m-    - name: Build and push Docker image[m
[31m-      uses: docker/build-push-action@v4[m
[31m-      with:[m
[31m-        context: .[m
[31m-        push: true[m
[31m-        tags: ${{ steps.meta.outputs.tags }}[m
[31m-        labels: ${{ steps.meta.outputs.labels }}[m
[31m-[m
[31m-  deploy:[m
[31m-    needs: build-and-push[m
[31m-    runs-on: ubuntu-latest[m
[31m-    if: github.event_name == 'push' && contains(github.ref, 'refs/tags/')[m
[31m-[m
[31m-    steps:[m
[31m-    - uses: actions/checkout@v3[m
[32m+[m[32m    - name: Check image exists[m
[32m+[m[32m      run: |[m
[32m+[m[32m        docker manifest inspect ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.set-tag.outputs.tag }}[m
 [m
     - name: Deploy to server via SSH[m
       uses: appleboy/ssh-action@v0.1.5[m
[36m@@ -61,8 +59,14 @@[m [mjobs:[m
         key: ${{ secrets.DEPLOY_KEY }}[m
         port: ${{ secrets.DEPLOY_PORT }}[m
         script: |[m
[31m-          docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}[m
[32m+[m[32m          docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.set-tag.outputs.tag }}[m
           docker stop php-app || true[m
           docker rm php-app || true[m
[31m-          docker run -d --name php-app -p 8080:80 ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}[m
[32m+[m[32m          docker run -d --name php-app -p 8080:80 \[m
[32m+[m[32m            --restart unless-stopped \[m
[32m+[m[32m            --health-cmd="curl -f http://localhost/ || exit 1" \[m
[32m+[m[32m            --health-interval=30s \[m
[32m+[m[32m            --health-timeout=3s \[m
[32m+[m[32m            --health-retries=3 \[m
[32m+[m[32m            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.set-tag.outputs.tag }}[m
           docker system prune -f[m
\ No newline at end of file[m
