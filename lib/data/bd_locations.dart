class BDLocations {
  static const List<String> districts = [
    'Bagerhat', 'Bandarban', 'Barguna', 'Barisal', 'Bhola',
    'Bogra', 'Brahmanbaria', 'Chandpur', 'Chapainawabganj', 'Chittagong',
    'Chuadanga', 'Comilla', 'Cox\'s Bazar', 'Dhaka', 'Dinajpur',
    'Faridpur', 'Feni', 'Gaibandha', 'Gazipur', 'Gopalganj',
    'Habiganj', 'Jamalpur', 'Jessore', 'Jhalokati', 'Jhenaidah',
    'Joypurhat', 'Khagrachari', 'Khulna', 'Kishoreganj', 'Kurigram',
    'Kushtia', 'Lakshmipur', 'Lalmonirhat', 'Madaripur', 'Magura',
    'Manikganj', 'Meherpur', 'Moulvibazar', 'Munshiganj', 'Mymensingh',
    'Naogaon', 'Narail', 'Narayanganj', 'Narsingdi', 'Natore',
    'Netrokona', 'Nilphamari', 'Noakhali', 'Pabna', 'Panchagarh',
    'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi', 'Rangamati',
    'Rangpur', 'Satkhira', 'Shariatpur', 'Sherpur', 'Sirajganj',
    'Sunamganj', 'Sylhet', 'Tangail', 'Thakurgaon',
  ];

  static List<String> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    return districts
        .where((d) => d.toLowerCase().contains(q))
        .toList();
  }
}