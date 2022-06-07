kubectl create secret generic \
  test-credentials \
  --from-literal=test.username=user \
  --from-literal=test.password=password