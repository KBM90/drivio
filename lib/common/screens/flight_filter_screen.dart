import 'package:drivio_app/common/models/flight_filter.dart';
import 'package:drivio_app/common/screens/flight_results_screen.dart';
import 'package:drivio_app/common/services/flight_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightFilterScreen extends StatefulWidget {
  const FlightFilterScreen({super.key});

  @override
  State<FlightFilterScreen> createState() => _FlightFilterScreenState();
}

class _FlightFilterScreenState extends State<FlightFilterScreen> {
  final _formKey = GlobalKey<FormState>();

  Airport? _selectedDepartureAirport;
  Airport? _selectedArrivalAirport;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedStatus = 'all';

  bool _isSearchingDeparture = false;
  bool _isSearchingArrival = false;

  List<Airport> _departureAirportSuggestions = [];
  List<Airport> _arrivalAirportSuggestions = [];

  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  Future<void> _searchDepartureAirports(String query) async {
    if (query.isEmpty) {
      setState(() {
        _departureAirportSuggestions = [];
        _isSearchingDeparture = false;
      });
      return;
    }

    setState(() {
      _isSearchingDeparture = true;
    });

    try {
      final airports = await FlightService.searchAirports(query);
      if (mounted) {
        setState(() {
          _departureAirportSuggestions = airports;
          _isSearchingDeparture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingDeparture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching airports: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchArrivalAirports(String query) async {
    if (query.isEmpty) {
      setState(() {
        _arrivalAirportSuggestions = [];
        _isSearchingArrival = false;
      });
      return;
    }

    setState(() {
      _isSearchingArrival = true;
    });

    try {
      final airports = await FlightService.searchAirports(query);
      if (mounted) {
        setState(() {
          _arrivalAirportSuggestions = airports;
          _isSearchingArrival = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingArrival = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching airports: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _searchFlights() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartureAirport == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a departure airport'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final filter = FlightFilter(
        departureIata: _selectedDepartureAirport!.iata,
        arrivalIata: _selectedArrivalAirport?.iata,
        startDate: _startDate,
        endDate: _endDate,
        flightStatus: _selectedStatus,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlightResultsScreen(filter: filter),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Flights'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            const Text(
              'Find Your Flight',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for flights by airport and date',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Departure Airport
            _buildAirportField(
              label: 'Departure Airport *',
              controller: _departureController,
              selectedAirport: _selectedDepartureAirport,
              suggestions: _departureAirportSuggestions,
              isSearching: _isSearchingDeparture,
              onChanged: _searchDepartureAirports,
              onSelected: (airport) {
                setState(() {
                  _selectedDepartureAirport = airport;
                  _departureController.text = airport.displayName;
                  _departureAirportSuggestions = [];
                });
              },
              onClear: () {
                setState(() {
                  _selectedDepartureAirport = null;
                  _departureController.clear();
                  _departureAirportSuggestions = [];
                });
              },
            ),

            const SizedBox(height: 16),

            // Arrival Airport (Optional)
            _buildAirportField(
              label: 'Arrival Airport (Optional)',
              controller: _arrivalController,
              selectedAirport: _selectedArrivalAirport,
              suggestions: _arrivalAirportSuggestions,
              isSearching: _isSearchingArrival,
              onChanged: _searchArrivalAirports,
              onSelected: (airport) {
                setState(() {
                  _selectedArrivalAirport = airport;
                  _arrivalController.text = airport.displayName;
                  _arrivalAirportSuggestions = [];
                });
              },
              onClear: () {
                setState(() {
                  _selectedArrivalAirport = null;
                  _arrivalController.clear();
                  _arrivalAirportSuggestions = [];
                });
              },
            ),

            const SizedBox(height: 16),

            // Date Range Picker
            InkWell(
              onTap: _selectDateRange,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date Range',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.date_range),
                ),
                child: Text(
                  '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Flight Status Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Flight Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.filter_list),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Flights')),
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'landed', child: Text('Landed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            // Search Button
            ElevatedButton(
              onPressed: _searchFlights,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text(
                    'Search Flights',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Type airport name or IATA code (e.g., JFK, LAX)\n'
                          '• Leave arrival airport empty to see all departures\n'
                          '• Results are cached for 15 minutes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirportField({
    required String label,
    required TextEditingController controller,
    required Airport? selectedAirport,
    required List<Airport> suggestions,
    required bool isSearching,
    required Function(String) onChanged,
    required Function(Airport) onSelected,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.flight_takeoff),
            suffixIcon:
                isSearching
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : selectedAirport != null
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                    : null,
          ),
          onChanged: (value) {
            if (selectedAirport != null) {
              setState(() {
                selectedAirport = null;
              });
            }
            onChanged(value);
          },
        ),
        if (suggestions.isNotEmpty && selectedAirport == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final airport = suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.local_airport),
                  title: Text(airport.name),
                  subtitle: Text(
                    '${airport.iata}${airport.city != null ? ' - ${airport.city}' : ''}',
                  ),
                  onTap: () => onSelected(airport),
                );
              },
            ),
          ),
      ],
    );
  }
}
