import { render } from '@testing-library/react';
import React, { useEffect } from 'react';
import styles from './index.module.css';

class ApiInteractionBox extends React.Component {

  constructor(props) {
    super(props);
    this.constructTable = this.constructTable.bind(this);
  }

  constructTable() {
    const { data } = this.props;
    const keys = data && data.length > 0 ? Object.keys(data[0]) : [];
    const cellWidth = keys.length / 100;
    return (
      <table>
        <thead>
          <tr>
            {keys.map(key => (
              <th width={`${cellWidth}%`}>{key}</th>
            ))}
          </tr>
        </thead>
        <tbody>
            {data && data.map(item => (
              <tr>
                {keys.map(key => (
                  <td width={`${cellWidth}%`}>{item[key]}</td>
                ))}
              </tr>
            ))}
        </tbody>
      </table>
    );
  }

  render() {
    const { children, title } = this.props;
    return (
        <div className={styles.apiInteractionBox}>
            <div className={`${styles.leftPanel} ${styles.panel}`}>
              <h2>{title}</h2>
              {children}
            </div>
            <div className={`${styles.rightPanel} ${styles.panel}`}>
              {this.constructTable()}
            </div>
        </div>
      );
  }
}

export default ApiInteractionBox;