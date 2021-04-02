import React, { useEffect } from 'react';
import ApiInteractionBox from './components/api-interaction-box';
import './App.css';
import { render } from '@testing-library/react';
import axios from 'axios';

class App extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      baseUrl: 'http://localhost:9292/api',
      ordersResponse: [],
      peopleResponse: [],
      searchBox: '',
    }
    this.fetchAll = this.fetchAll.bind(this);
    this.fetchOrderStreaks = this.fetchOrderStreaks.bind(this);
    this.fetchMonthlyPizzas = this.fetchMonthlyPizzas.bind(this);
    this.searchPeopleByName = this.searchPeopleByName.bind(this);
    this.searchOrdersByType = this.searchOrdersByType.bind(this);
  }

  fetchAll(db) {
    const { baseUrl } = this.state;
    fetch(`${baseUrl}/${db}/all`)
      .then(response => response.json())
      .then(data => this.setState({ [`${db}Response`]: data }))
      .catch(err => console.log(err));
  }

  fetchOrderStreaks() {
    const { baseUrl } = this.state;
    fetch(`${baseUrl}/orders/streaks`)
      .then(response => response.json())
      .then(data => this.setState({ ordersResponse: data }))
      .catch(err => console.log(err));
  }

  fetchMonthlyPizzas() {
    const { baseUrl } = this.state;
    fetch(`${baseUrl}/orders/bestmonth`)
      .then(response => response.json())
      .then(data => this.setState({ ordersResponse: data }))
      .catch(err => console.log(err));
  }

  searchPeopleByName() {
    const { baseUrl, searchBox } = this.state;
    fetch(`${baseUrl}/people/fetchbyname`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: searchBox })
    })
      .then(response => response.json())
      .then(data => this.setState({ peopleResponse: data }))
      .catch(err => console.log(err))
  }

  searchOrdersByType(type) {
    const { baseUrl } = this.state;
    fetch(`${baseUrl}/orders/fetchordersbytype`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type })
    })
      .then(response => response.json())
      .then(data => this.setState({ ordersResponse: data }))
      .catch(err => console.log(err))
  }

  render() {
    const { ordersResponse, peopleResponse } = this.state;
    return (
      <div className="App">
        <ApiInteractionBox title="Orders" data={ordersResponse}>
          <select onChange={(e) => this.searchOrdersByType(e.currentTarget.value)}>
            <option value="" disabled selected>Choose a meat type</option>
            <option value="sausage">Sausage</option>
            <option value="pepperoni">Pepperoni</option>
            <option value="pineapple">Pineapple</option>
          </select>
          <button onClick={() => this.fetchAll('orders')}>Fetch All Orders</button>
          <button onClick={this.fetchOrderStreaks}>Fetch Order Streaks</button>
          <button onClick={this.fetchMonthlyPizzas}>Fetch Monthly Pizzas</button>
        </ApiInteractionBox>
        <ApiInteractionBox title="People" data={peopleResponse}>
          <div className={"search"}>
            <input placeholder="Search by name..." onChange={(e) => { this.setState({ searchBox: e.currentTarget.value }) }} type="text" />
            <button className="searchBtn" onClick={this.searchPeopleByName}>Search</button>
          </div>
          <button onClick={() => this.fetchAll('people')}>Fetch All People</button>
        </ApiInteractionBox>
      </div>
    );
  }
}

export default App;
