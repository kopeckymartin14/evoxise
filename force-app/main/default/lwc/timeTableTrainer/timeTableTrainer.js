import { LightningElement, track, wire, api } from 'lwc';
import schedulerData from '@salesforce/apex/SchedulerCMPController.schedulerData';
import getTrainer from '@salesforce/apex/SchedulerCMPController.getTrainer';
//import getWeeklySchedule from '@salesforce/apex/chedulerV2.getWeeklySchedule';

import { CurrentPageReference } from 'lightning/navigation';


export default class TimeTableTrainer extends LightningElement {
    @track tablesData = []; // Array to hold table data
    numberOfDays = 7; // Default number of days to display
    dummyData = [];
    trainerData = [];
    @track currentPage = 1; // Start with the first page
    @track recordsPerPage = 5; // Show 5 records per page

    xtoken;
    trainer;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            this.xtoken = pageRef.state.token; // Get the xtoken from the URL parameters
        }
    }

    connectedCallback() {
        console.log('token: ', this.xtoken);
        getTrainer({ xToken: this.xtoken })
          .then(code => {
            console.log('code: ', code);

            this.trainer = code != null ? code : '0Hn9V000000HOfRSAW';
            schedulerData({serviceTeritoryId : null, trainerId : this.trainer})
                .then(result =>{
                    this.dummyData = result;
                    console.log('data ', result);
                    this.updatePaginatedData(); // Initialize paginated data after fetching the result
                }).catch(error =>{
                    console.log('error ' + JSON.stringify(error));
                });
                
          })
          .catch(error => {
            console.error('Error:', error);
        });
        //this.fetchWeeklySchedule();
        
    }

    fetchWeeklySchedule() {
        getWeeklySchedule({ numberOfDays: this.numberOfDays })
            .then(result => {
                this.tablesData = result.map(item => ({
                    ...item,
                    // Transform slots to an object with time slots as keys
                    slotsMap: item.slots.reduce((acc, slot) => {
                        acc[slot] = { time: slot, appointments: [] };
                        return acc;
                    }, {})
                }));
                console.log('Data received:', this.tablesData);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
            });
    }
      // Method to update paginated data based on currentPage
      updatePaginatedData() {
        const startIdx = (this.currentPage - 1) * this.recordsPerPage;
        const endIdx = this.currentPage * this.recordsPerPage;
        this.paginatedData = this.dummyData.slice(startIdx, endIdx);
    }

    // Method to handle previous page
    
    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePaginatedData();
        }
    }

    // Method to handle next page
    handleNext() {
        if (this.currentPage < Math.ceil(this.dummyData.length / this.recordsPerPage)) {
            this.currentPage += 1;
            this.updatePaginatedData();
        }
    }

    // Getters to control disabling of next/previous buttons
    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === Math.ceil(this.dummyData.length / this.recordsPerPage);
    }

    /*dummyData = [
        {
            dayName: 'Monday',
            dayDate: '2024-07-15',
            startTime: '08:00:00.000',
            endTime: '17:00:00.000',
            workingHours: ['08:00', '14:00' , '15:00' , '17:00'],
            mainData: [
                {
                    resName: 'Resource 1',
                    scheduledTimes: [
                        { boxes: ['red', 'red', 'red', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 2',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 3',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                }
            ]
        },
        {
            dayName: 'Tuesday',
            dayDate: '2024-07-16',
            startTime: '08:00:00.000',
            endTime: '17:00:00.000',
            workingHours: ['08:00', '14:00' , '15:00' , '17:00'],
            mainData: [
                {
                    resName: 'Resource 1',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 2',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 3',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                }
            ]
        },
        {
            dayName: 'Wednesday',
            dayDate: '2024-07-17',
            startTime: '08:00:00.000',
            endTime: '17:00:00.000',
            workingHours: ['08:00', '14:00' , '15:00' , '17:00'],
            mainData: [
                {
                    resName: 'Resource 1',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 2',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                },
                {
                    resName: 'Resource 3',
                    scheduledTimes: [
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] },
                        { boxes: ['white', 'red', 'white', 'red'] },
                        { boxes: ['red', 'white', 'red', 'white'] }
                    ]
                }
            ]
        }
    ];*/
}