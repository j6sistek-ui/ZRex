FROM node:24-alpine
WORKDIR /work
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY mod/ ./mod/
COPY tests/ ./tests/
CMD ["npm", "test"]
