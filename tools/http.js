const axios = require('axios');

class HttpClient {
  constructor(baseURL) {
    this.client = axios.create({
      baseURL,
    });
  }

  async get(url, params = {}) {
    try {
      const response = await this.client.get(url, { params });
      return response.data;
    } catch (error) {
      console.error(`Failed to get data from ${url}: ${error}`);
      throw error;
    }
  }

  async post(url, data = {}) {
    try {
      const response = await this.client.post(url, data);
      return response.data;
    } catch (error) {
      console.error(`Failed to post data to ${url}: ${error}`);
      throw error;
    }
  }

  async put(url, data = {}) {
    try {
      const response = await this.client.put(url, data);
      return response.data;
    } catch (error) {
      console.error(`Failed to put data to ${url}: ${error}`);
      throw error;
    }
  }

  async delete(url) {
    try {
      const response = await this.client.delete(url);
      return response.data;
    } catch (error) {
      console.error(`Failed to delete data from ${url}: ${error}`);
      throw error;
    }
  }
}

module.exports = HttpClient;