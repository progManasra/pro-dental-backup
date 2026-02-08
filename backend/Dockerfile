FROM node:20

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

COPY src ./src

EXPOSE 8091
CMD ["node", "src/server.js"]
